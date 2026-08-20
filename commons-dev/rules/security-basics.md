# Security basics

Apply these defaults to every change that handles data, input, or credentials.

- Never hard-code secrets, tokens, or credentials in source or logs. Read them from
  environment variables or a secrets manager.
- Validate and sanitize external input: request payloads, file contents, command
  arguments, and anything crossing a trust boundary.
- Use parameterized queries and safe APIs. Never build SQL, shell commands, or HTML by
  string concatenation of untrusted values.
- Grant the least privilege that works: narrow scopes, tokens, and file permissions.
- Do not send code, secrets, or user data to external services without a clear reason
  and authorization.
