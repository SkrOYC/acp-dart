import { execFileSync, spawn } from "node:child_process";
import { Readable, Writable } from "node:stream";

type SessionMessage =
  | { kind: "stop"; response: { stopReason: string } }
  | {
      kind: "session_update";
      notification: { update: { sessionUpdate: string } };
    };

type ActiveSession = {
  sessionId: string;
  prompt(
    prompt: string,
    options?: { cancellationSignal?: AbortSignal },
  ): Promise<{ stopReason: string }>;
  nextUpdate(): Promise<SessionMessage>;
};

type ClientContext = {
  request<T = unknown>(method: string, params: object): Promise<T>;
  notify(method: string, params: object): Promise<void>;
  buildSession(cwd: string): {
    withSession<T>(
      operation: (session: ActiveSession) => Promise<T>,
    ): Promise<T>;
  };
};

type PermissionContext = {
  params: {
    options: Array<{ kind: string; optionId: string }>;
  };
};

const root = process.env.ACP_DART_ROOT;
const sdkRoot = process.env.ACP_TYPESCRIPT_SDK_DIR;
if (!root || !sdkRoot) {
  throw new Error("Set ACP_DART_ROOT and ACP_TYPESCRIPT_SDK_DIR");
}

const acp = await import(`${sdkRoot}/src/acp.ts`);
const sdkTag = execFileSync(
  "git",
  ["-C", sdkRoot, "describe", "--tags", "--exact-match", "HEAD"],
  {
    encoding: "utf8",
  },
).trim();
if (sdkTag !== "v1.5.0") {
  throw new Error(
    `Expected TypeScript SDK tag v1.5.0, found ${sdkTag || "untagged"}`,
  );
}
const agent = spawn("dart", ["run", "example/agent.dart"], {
  cwd: root,
  stdio: ["pipe", "pipe", "inherit"],
});
const agentStdin = agent.stdin;
const agentStdout = agent.stdout;
if (agentStdin === null || agentStdout === null) {
  throw new Error("Unable to open Dart agent stdio pipes");
}
const input = Writable.toWeb(agentStdin);
const output = Readable.toWeb(agentStdout);
const updates: string[] = [];
let permissionRequests = 0;
let cancellationNotifications = 0;
let agentStopped = false;
const stopAgent = () => {
  if (agentStopped) return;
  agentStopped = true;
  agent.kill();
};
process.on("SIGTERM", () => {
  stopAgent();
  process.exit(143);
});
process.on("SIGINT", () => {
  stopAgent();
  process.exit(130);
});

try {
  // A malformed line must not prevent the next valid request from being read.
  agentStdin.write("{malformed-json}\n");
  const app = acp
    .client({ name: "typescript-v1.5-interop" })
    .onRequest(
      acp.methods.client.session.requestPermission,
      (ctx: PermissionContext) => {
        permissionRequests++;
        const option = ctx.params.options.find((item: { kind: string }) =>
          item.kind.startsWith("allow"),
        );
        if (!option) throw new Error("Agent did not offer an allow option");
        return { outcome: { outcome: "selected", optionId: option.optionId } };
      },
    );

  const transport = acp.ndJsonStream(input, output);
  const transportWriter = transport.writable.getWriter();
  const observedTransport = {
    readable: transport.readable,
    writable: new WritableStream({
      write(message: unknown) {
        if (
          typeof message === "object" &&
          message !== null &&
          "method" in message &&
          message.method === "$/cancel_request"
        ) {
          cancellationNotifications++;
        }
        return transportWriter.write(message);
      },
      close() {
        return transportWriter.close();
      },
      abort(reason) {
        return transportWriter.abort(reason);
      },
    }),
  };

  const result: {
    promptResponse: { stopReason: string };
    sessionCancelStopReason: string;
    cancellationStopReason: string;
  } = await app.connectWith(observedTransport, async (ctx: ClientContext) => {
    const initialized = await ctx.request<{ protocolVersion: number }>(
      acp.methods.agent.initialize,
      {
        protocolVersion: acp.PROTOCOL_VERSION,
        clientCapabilities: {},
      },
    );
    if (initialized.protocolVersion !== acp.PROTOCOL_VERSION) {
      throw new Error(
        `Unexpected protocol version ${initialized.protocolVersion}`,
      );
    }

    let methodNotFoundCode: number | undefined;
    try {
      await ctx.request("interop/unknown_method", {});
    } catch (error) {
      if (
        typeof error === "object" &&
        error !== null &&
        "code" in error &&
        typeof error.code === "number"
      ) {
        methodNotFoundCode = error.code;
      }
    }
    if (methodNotFoundCode !== -32601) {
      throw new Error(
        `Expected JSON-RPC method-not-found, got ${methodNotFoundCode}`,
      );
    }

    return ctx.buildSession(root).withSession(async (session) => {
      await session.prompt(
        "Please inspect and update the project configuration.",
      );
      let promptResponse: { stopReason: string } | undefined;
      for (;;) {
        const message = await session.nextUpdate();
        if (message.kind === "stop") {
          promptResponse = message.response;
          break;
        }
        updates.push(message.notification.update.sessionUpdate);
      }
      if (!promptResponse)
        throw new Error("Prompt finished without a response");

      const sessionCancelPrompt = session.prompt(
        "Please begin a cancellable turn.",
      );
      await session.nextUpdate();
      await ctx.notify(acp.methods.agent.session.cancel, {
        sessionId: session.sessionId,
      });
      let sessionCancelResponse: { stopReason: string } | undefined;
      for (;;) {
        const message = await session.nextUpdate();
        if (message.kind === "stop") {
          sessionCancelResponse = message.response;
          break;
        }
      }
      await sessionCancelPrompt;
      if (!sessionCancelResponse) {
        throw new Error("session/cancel finished without a response");
      }
      if (sessionCancelResponse.stopReason !== "cancelled") {
        throw new Error(
          `Unexpected session/cancel stop reason ${sessionCancelResponse.stopReason}`,
        );
      }

      const cancellation = new AbortController();
      const cancelledPrompt = session.prompt("Please begin another turn.", {
        cancellationSignal: cancellation.signal,
      });
      setTimeout(() => cancellation.abort(), 100);
      const cancellationResponse = await cancelledPrompt;
      if (
        !["cancelled", "end_turn"].includes(cancellationResponse.stopReason)
      ) {
        throw new Error(
          `Unexpected cancellation response ${cancellationResponse.stopReason}`,
        );
      }
      return {
        promptResponse,
        sessionCancelStopReason: sessionCancelResponse.stopReason,
        cancellationStopReason: cancellationResponse.stopReason,
      };
    });
  });

  const expected = ["agent_message_chunk", "tool_call", "tool_call_update"];
  if (!expected.every((name) => updates.includes(name))) {
    throw new Error(`Missing session updates: ${updates.join(", ")}`);
  }
  if (permissionRequests < 1) {
    throw new Error(`Expected a permission request, got ${permissionRequests}`);
  }
  if (result.promptResponse.stopReason !== "end_turn") {
    throw new Error(
      `Unexpected prompt stop reason ${result.promptResponse.stopReason}`,
    );
  }
  if (!["cancelled", "end_turn"].includes(result.cancellationStopReason)) {
    throw new Error(
      `Unexpected cancellation response ${result.cancellationStopReason}`,
    );
  }
  if (cancellationNotifications !== 1) {
    throw new Error(
      `Expected one $/cancel_request notification, got ${cancellationNotifications}`,
    );
  }
  if (result.sessionCancelStopReason !== "cancelled") {
    throw new Error(
      `Unexpected session/cancel stop reason ${result.sessionCancelStopReason}`,
    );
  }
  console.log(
    JSON.stringify({
      protocolVersion: acp.PROTOCOL_VERSION,
      updates,
      permissionRequests,
      stopReason: result.promptResponse.stopReason,
      sessionCancelStopReason: result.sessionCancelStopReason,
      cancellationStopReason: result.cancellationStopReason,
      cancellationNotifications,
    }),
  );
} finally {
  stopAgent();
}
