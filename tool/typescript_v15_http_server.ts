import { execFileSync } from "node:child_process";
import { createServer } from "node:http";

interface PromptParams {
  readonly sessionId: string;
  readonly prompt: Array<{ readonly type: string; readonly text?: string }>;
}

interface CancelParams {
  readonly sessionId: string;
}

interface RequestContext<Params> {
  readonly params: Params;
  readonly signal: AbortSignal;
  readonly client: {
    request<Response>(method: string, params: object): Promise<Response>;
    notify(method: string, params: object): Promise<void>;
  };
}

interface Deferred {
  readonly promise: Promise<void>;
  resolve(): void;
}

const sdkRoot = process.env.ACP_TYPESCRIPT_SDK_DIR;
if (!sdkRoot) {
  throw new Error("Set ACP_TYPESCRIPT_SDK_DIR");
}

const sdkTag = execFileSync(
  "git",
  ["-C", sdkRoot, "describe", "--tags", "--exact-match", "HEAD"],
  { encoding: "utf8" },
).trim();
if (sdkTag !== "v1.5.0") {
  throw new Error(`Expected TypeScript SDK tag v1.5.0, found ${sdkTag}`);
}

const acp = await import(`${sdkRoot}/src/acp.ts`);
const { AcpServer } = await import(`${sdkRoot}/src/server.ts`);
const { createNodeHttpHandler } = await import(
  `${sdkRoot}/src/node-adapter.ts`
);

const sessions = new Set<string>();
const sessionCancels = new Map<string, Deferred>();
const permissionOutcomes: string[] = [];
const requestCounts = {
  cookie: 0,
  authenticated: 0,
  connectionHeader: 0,
  sessionHeader: 0,
  initialize: 0,
  prompt: 0,
  permission: 0,
  fileRead: 0,
  sessionCancel: 0,
  requestCancel: 0,
};

let nextSession = 0;

function deferred(): Deferred {
  let resolvePromise: (() => void) | undefined;
  const promise = new Promise<void>((resolve) => {
    resolvePromise = resolve;
  });
  return {
    promise,
    resolve() {
      resolvePromise?.();
    },
  };
}

function promptText(params: PromptParams): string {
  return params.prompt
    .filter((block) => block.type === "text")
    .map((block) => block.text ?? "")
    .join("");
}

function abortPromise(signal: AbortSignal): Promise<void> {
  if (signal.aborted) {
    requestCounts.requestCancel += 1;
    return Promise.resolve();
  }
  return new Promise((resolve) => {
    signal.addEventListener(
      "abort",
      () => {
        requestCounts.requestCancel += 1;
        resolve();
      },
      { once: true },
    );
  });
}

const agent = acp
  .agent({ name: "typescript-v1.5-stress-agent" })
  .onRequest(acp.methods.agent.initialize, () => {
    requestCounts.initialize += 1;
    return {
      protocolVersion: acp.PROTOCOL_VERSION,
      agentCapabilities: { loadSession: false },
      authMethods: [],
    };
  })
  .onRequest(acp.methods.agent.session.new, () => {
    nextSession += 1;
    const sessionId = `ts-session-${nextSession}`;
    sessions.add(sessionId);
    return { sessionId };
  })
  .onRequest(
    acp.methods.agent.session.prompt,
    async (context: RequestContext<PromptParams>) => {
      requestCounts.prompt += 1;
      const { sessionId } = context.params;
      if (!sessions.has(sessionId)) {
        throw acp.RequestError.resourceNotFound(sessionId);
      }

      const text = promptText(context.params);
      if (text === "cancel-with-session") {
        const cancellation = deferred();
        sessionCancels.set(sessionId, cancellation);
        await cancellation.promise;
        sessionCancels.delete(sessionId);
        return { stopReason: "cancelled" };
      }
      if (text === "cancel-with-request") {
        await abortPromise(context.signal);
        return { stopReason: "cancelled" };
      }

      await context.client.notify(acp.methods.client.session.update, {
        sessionId,
        update: {
          sessionUpdate: "agent_message_chunk",
          content: { type: "text", text: `${text}:first` },
        },
      });
      const permission = await context.client.request<{
        outcome: { outcome: string; optionId?: string };
      }>(acp.methods.client.session.requestPermission, {
        sessionId,
        toolCall: { toolCallId: `${text}-${sessionId}`, title: "Read file" },
        options: [
          { kind: "allow_once", name: "Allow once", optionId: "allow" },
          { kind: "reject_once", name: "Reject once", optionId: "reject" },
        ],
      });
      requestCounts.permission += 1;
      permissionOutcomes.push(
        permission.outcome.outcome === "selected"
          ? (permission.outcome.optionId ?? "missing")
          : permission.outcome.outcome,
      );
      const file = await context.client.request<{ content: string }>(
        acp.methods.client.fs.readTextFile,
        { sessionId, path: "/virtual/project.txt", line: 1, limit: 20 },
      );
      requestCounts.fileRead += 1;
      await context.client.notify(acp.methods.client.session.update, {
        sessionId,
        update: {
          sessionUpdate: "agent_message_chunk",
          content: {
            type: "text",
            text: `${text}:second:${permission.outcome.optionId}:${file.content}`,
          },
        },
      });
      return { stopReason: "end_turn" };
    },
  )
  .onNotification(
    acp.methods.agent.session.cancel,
    (context: { readonly params: CancelParams }) => {
      requestCounts.sessionCancel += 1;
      sessionCancels.get(context.params.sessionId)?.resolve();
    },
  );

const acpServer = new AcpServer({ agent });
const acpHandler = createNodeHttpHandler(acpServer);
const httpServer = createServer((request, response) => {
  const path = new URL(request.url ?? "/", "http://127.0.0.1").pathname;
  if (path === "/metrics") {
    response.writeHead(200, { "Content-Type": "application/json" });
    response.end(JSON.stringify({ ...requestCounts, permissionOutcomes }));
    return;
  }
  if (path !== "/acp") {
    response.writeHead(404).end();
    return;
  }
  if (request.headers["x-interop-token"] === "dart-client") {
    requestCounts.authenticated += 1;
  }
  if (request.headers.cookie?.includes("affinity=ts-peer")) {
    requestCounts.cookie += 1;
  }
  if (request.headers["acp-connection-id"]) {
    requestCounts.connectionHeader += 1;
  }
  if (request.headers["acp-session-id"]) {
    requestCounts.sessionHeader += 1;
  }
  response.setHeader("Set-Cookie", "affinity=ts-peer; Path=/; SameSite=Lax");
  acpHandler(request, response);
});

httpServer.listen(0, "127.0.0.1", () => {
  const address = httpServer.address();
  if (address === null || typeof address === "string") {
    throw new Error("TypeScript stress server did not bind a TCP port");
  }
  process.stdout.write(
    `${JSON.stringify({ url: `http://127.0.0.1:${address.port}/acp` })}\n`,
  );
});

let closing = false;
async function close(): Promise<void> {
  if (closing) return;
  closing = true;
  await acpServer.close();
  await new Promise<void>((resolve, reject) => {
    httpServer.close((error) => {
      if (error) reject(error);
      else resolve();
    });
  });
}

process.on("SIGTERM", () => {
  void close().finally(() => process.exit(0));
});
process.on("SIGINT", () => {
  void close().finally(() => process.exit(0));
});
