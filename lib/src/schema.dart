/// The role of a message sender.
enum Role {
  assistant,
  user,
}

/// The kind of a tool.
enum ToolKind {
  read,
  edit,
  delete,
  move,
  search,
  execute,
  think,
  fetch,
  switch_mode,
  other,
}

/// The status of a tool call.
enum ToolCallStatus {
  pending,
  in_progress,
  completed,
  failed,
}
