import { execFileSync } from "node:child_process";

interface ClientContext {
  request<Response>(
    method: string,
    params: object,
    options?: { readonly cancellationSignal?: AbortSignal },
  ): Promise<Response>;
  notify(method: string, params: object): Promise<void>;
}

interface SessionUpdateContext {
  readonly params: {
    readonly sessionId: string;
    readonly update: {
      readonly sessionUpdate: string;
      readonly content?: { readonly type: string; readonly text?: string };
    };
  };
}

interface PermissionContext {
  readonly params: {
    readonly toolCall: { readonly toolCallId: string };
    readonly options: Array<{ readonly optionId: string }>;
  };
}

interface ReadContext {
  readonly params: { readonly path: string };
}

interface StressSummary {
  transport: string;
  rounds: number;
  prompts: number;
  updates: number;
  permissions: number;
  fileReads: number;
  methodNotFoundCode?: number;
  resourceNotFoundCode?: number;
  sessionCancelStopReason?: string;
  requestCancelStopReason?: string;
  malformedStatus?: number;
  malformedWebSocketRecovered?: boolean;
  observedConnectionHeaders: number;
  observedSessionHeaders: number;
  observedCustomHeaders: number;
}

const sdkRoot = process.env.ACP_TYPESCRIPT_SDK_DIR;
const endpoint = process.env.ACP_INTEROP_URL;
const transportName = process.env.ACP_INTEROP_TRANSPORT;
if (!sdkRoot || !endpoint || !transportName) {
  throw new Error(
    "Set ACP_TYPESCRIPT_SDK_DIR, ACP_INTEROP_URL, and ACP_INTEROP_TRANSPORT",
  );
}
if (transportName !== "http" && transportName !== "websocket") {
  throw new Error(`Unsupported transport ${transportName}`);
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
const http = await import(`${sdkRoot}/src/http-stream.ts`);
const ws = await import(`${sdkRoot}/src/ws-stream.ts`);

const summary: StressSummary = {
  transport: transportName,
  rounds: 0,
  prompts: 0,
  updates: 0,
  permissions: 0,
  fileReads: 0,
  observedConnectionHeaders: 0,
  observedSessionHeaders: 0,
  observedCustomHeaders: 0,
};
const updates = new Map<string, string[]>();

function requestErrorCode(error: unknown): number | undefined {
  if (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    typeof error.code === "number"
  ) {
    return error.code;
  }
  return undefined;
}

function textUpdate(context: SessionUpdateContext): void {
  const { sessionId, update } = context.params;
  if (
    update.sessionUpdate !== "agent_message_chunk" ||
    update.content?.type !== "text"
  ) {
    return;
  }
  const values = updates.get(sessionId) ?? [];
  values.push(update.content.text ?? "");
  updates.set(sessionId, values);
  summary.updates += 1;
}

function permissionResponse(context: PermissionContext): object {
  summary.permissions += 1;
  const id = context.params.toolCall.toolCallId;
  if (id.includes("cancel-permission")) {
    return { outcome: { outcome: "cancelled" } };
  }
  const wanted = id.includes("reject-permission") ? "reject" : "allow";
  const option = context.params.options.find(
    (candidate) => candidate.optionId === wanted,
  );
  if (!option) throw new Error(`Missing ${wanted} permission option`);
  return { outcome: { outcome: "selected", optionId: option.optionId } };
}

function readResponse(context: ReadContext): object {
  summary.fileReads += 1;
  if (context.params.path !== "/virtual/project.txt") {
    throw new Error(`Unexpected read path ${context.params.path}`);
  }
  return { content: "typescript-client-file" };
}

const observingFetch: typeof globalThis.fetch = async (input, init) => {
  const request = new Request(input, init);
  if (request.headers.get("Acp-Connection-Id")) {
    summary.observedConnectionHeaders += 1;
  }
  if (request.headers.get("Acp-Session-Id")) {
    summary.observedSessionHeaders += 1;
  }
  if (request.headers.get("X-Interop-Token") === "typescript-client") {
    summary.observedCustomHeaders += 1;
  }
  return await fetch(request);
};

function createStream(): {
  readable: ReadableStream;
  writable: WritableStream;
} {
  if (transportName === "http") {
    return http.createHttpStream(endpoint, {
      fetch: observingFetch,
      headers: { "X-Interop-Token": "typescript-client" },
    });
  }
  return ws.createWebSocketStream(endpoint);
}

async function runRound(full: boolean): Promise<void> {
  const app = acp
    .client({ name: "typescript-v1.5-stress-client" })
    .onRequest(acp.methods.client.session.requestPermission, permissionResponse)
    .onRequest(acp.methods.client.fs.readTextFile, readResponse)
    .onNotification(acp.methods.client.session.update, textUpdate);

  await app.connectWith(createStream(), async (context: ClientContext) => {
    const initialized = await context.request<{ protocolVersion: number }>(
      acp.methods.agent.initialize,
      {
        protocolVersion: acp.PROTOCOL_VERSION,
        clientCapabilities: {
          fs: { readTextFile: true, writeTextFile: false },
        },
      },
    );
    if (initialized.protocolVersion !== acp.PROTOCOL_VERSION) {
      throw new Error(
        `Unexpected protocol version ${initialized.protocolVersion}`,
      );
    }

    if (!full) {
      const reconnectSession = await context.request<{ sessionId: string }>(
        acp.methods.agent.session.new,
        { cwd: "/interop/reconnect", mcpServers: [] },
      );
      const reconnectPrompt = await context.request<{ stopReason: string }>(
        acp.methods.agent.session.prompt,
        {
          sessionId: reconnectSession.sessionId,
          prompt: [{ type: "text", text: "reconnect" }],
        },
      );
      if (reconnectPrompt.stopReason !== "end_turn") {
        throw new Error("Reconnect prompt did not complete");
      }
      summary.prompts += 1;
      summary.rounds += 1;
      return;
    }

    try {
      await context.request("interop/missing", {});
    } catch (error: unknown) {
      summary.methodNotFoundCode = requestErrorCode(error);
    }
    if (summary.methodNotFoundCode !== -32601) {
      throw new Error(`Expected -32601, got ${summary.methodNotFoundCode}`);
    }

    try {
      await context.request(acp.methods.agent.session.prompt, {
        sessionId: "missing-session",
        prompt: [{ type: "text", text: "invalid" }],
      });
    } catch (error: unknown) {
      summary.resourceNotFoundCode = requestErrorCode(error);
    }
    if (summary.resourceNotFoundCode !== -32002) {
      throw new Error(`Expected -32002, got ${summary.resourceNotFoundCode}`);
    }

    const labels = [
      "allow-permission",
      "reject-permission",
      "cancel-permission",
    ];
    const sessions = await Promise.all(
      labels.map((label) =>
        context.request<{ sessionId: string }>(acp.methods.agent.session.new, {
          cwd: `/interop/${label}`,
          mcpServers: [],
        }),
      ),
    );
    const responses = await Promise.all(
      sessions.map((session, index) =>
        context.request<{ stopReason: string }>(
          acp.methods.agent.session.prompt,
          {
            sessionId: session.sessionId,
            prompt: [{ type: "text", text: labels[index] }],
          },
        ),
      ),
    );
    if (responses.some((response) => response.stopReason !== "end_turn")) {
      throw new Error("A concurrent prompt did not finish with end_turn");
    }
    for (const [index, session] of sessions.entries()) {
      const values = updates.get(session.sessionId) ?? [];
      if (
        values.length !== 2 ||
        values[0] !== `${labels[index]}:first` ||
        !values[1]?.startsWith(`${labels[index]}:second:`)
      ) {
        throw new Error(
          `Out-of-order updates for ${session.sessionId}: ${values.join("|")}`,
        );
      }
    }
    summary.prompts += responses.length;

    const sessionCancel = await context.request<{ sessionId: string }>(
      acp.methods.agent.session.new,
      { cwd: "/interop/session-cancel", mcpServers: [] },
    );
    const sessionPrompt = context.request<{ stopReason: string }>(
      acp.methods.agent.session.prompt,
      {
        sessionId: sessionCancel.sessionId,
        prompt: [{ type: "text", text: "cancel-with-session" }],
      },
    );
    await new Promise((resolve) => setTimeout(resolve, 50));
    await context.notify(acp.methods.agent.session.cancel, {
      sessionId: sessionCancel.sessionId,
    });
    summary.sessionCancelStopReason = (await sessionPrompt).stopReason;

    const requestCancel = await context.request<{ sessionId: string }>(
      acp.methods.agent.session.new,
      { cwd: "/interop/request-cancel", mcpServers: [] },
    );
    const controller = new AbortController();
    const requestPrompt = context.request<{ stopReason: string }>(
      acp.methods.agent.session.prompt,
      {
        sessionId: requestCancel.sessionId,
        prompt: [{ type: "text", text: "cancel-with-request" }],
      },
      { cancellationSignal: controller.signal },
    );
    await new Promise((resolve) => setTimeout(resolve, 50));
    controller.abort();
    summary.requestCancelStopReason = (await requestPrompt).stopReason;
    summary.rounds += 1;
  });
}

async function malformedHttpProbe(): Promise<void> {
  const response = await fetch(endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: "{malformed-json",
  });
  summary.malformedStatus = response.status;
  await response.text();
  if (response.status !== 400) {
    throw new Error(`Malformed HTTP request returned ${response.status}`);
  }
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

async function nextWebSocketMessage(socket: WebSocket): Promise<unknown> {
  return await new Promise((resolve, reject) => {
    const onMessage = (event: MessageEvent): void => {
      cleanup();
      try {
        resolve(JSON.parse(String(event.data)) as unknown);
      } catch (error: unknown) {
        reject(error instanceof Error ? error : new Error(String(error)));
      }
    };
    const onError = (): void => {
      cleanup();
      reject(new Error("WebSocket probe failed"));
    };
    const cleanup = (): void => {
      socket.removeEventListener("message", onMessage);
      socket.removeEventListener("error", onError);
    };
    socket.addEventListener("message", onMessage, { once: true });
    socket.addEventListener("error", onError, { once: true });
  });
}

async function malformedWebSocketProbe(): Promise<void> {
  const socket = new WebSocket(endpoint);
  await new Promise<void>((resolve, reject) => {
    socket.addEventListener("open", () => resolve(), { once: true });
    socket.addEventListener(
      "error",
      () => reject(new Error("WebSocket probe could not connect")),
      { once: true },
    );
  });
  const initialized = nextWebSocketMessage(socket);
  socket.send(
    JSON.stringify({
      jsonrpc: "2.0",
      id: "init",
      method: "initialize",
      params: { protocolVersion: 1, clientCapabilities: {} },
    }),
  );
  await initialized;
  const parseErrorMessage = nextWebSocketMessage(socket);
  socket.send("{malformed-json");
  const parseError = await parseErrorMessage;
  if (
    !isRecord(parseError) ||
    !isRecord(parseError.error) ||
    parseError.error.code !== -32700
  ) {
    throw new Error("WebSocket malformed frame did not return -32700");
  }
  const recoveredMessage = nextWebSocketMessage(socket);
  socket.send(
    JSON.stringify({
      jsonrpc: "2.0",
      id: "new",
      method: "session/new",
      params: { cwd: "/interop/malformed-recovery", mcpServers: [] },
    }),
  );
  const recovered = await recoveredMessage;
  if (!isRecord(recovered) || !isRecord(recovered.result)) {
    throw new Error("WebSocket did not recover after malformed frame");
  }
  summary.malformedWebSocketRecovered = true;
  socket.close();
}

if (transportName === "http") {
  await malformedHttpProbe();
} else {
  await malformedWebSocketProbe();
}
await runRound(true);
await runRound(false);

if (summary.sessionCancelStopReason !== "cancelled") {
  throw new Error(
    `Unexpected session cancellation ${summary.sessionCancelStopReason}`,
  );
}
if (summary.requestCancelStopReason !== "cancelled") {
  throw new Error(
    `Unexpected request cancellation ${summary.requestCancelStopReason}`,
  );
}
if (summary.permissions !== 4 || summary.fileReads !== 4) {
  throw new Error(
    `Expected four client callbacks, got ${summary.permissions}/${summary.fileReads}`,
  );
}
if (
  transportName === "http" &&
  (summary.observedConnectionHeaders === 0 ||
    summary.observedSessionHeaders === 0 ||
    summary.observedCustomHeaders === 0)
) {
  throw new Error("HTTP routing or custom headers were not observed");
}

process.stdout.write(`${JSON.stringify(summary)}\n`);
