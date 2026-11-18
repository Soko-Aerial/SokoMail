# SokoMail Go API: client integration notes

The Go API does not exist yet. This page records what the Flutter client
**already assumes** and what must be **agreed with the backend team** before
any endpoint is implemented. Nothing here defines endpoint behaviour.

## Already implemented on the client

| Concern | Client behaviour | Where |
| --- | --- | --- |
| Base URL | `--dart-define=API_BASE_URL=https://...`; HTTPS required in release builds | `core/config/app_config.dart` |
| Format | JSON requests and responses (`Accept` / `Content-Type: application/json`) | `core/network/api_client.dart` |
| Client header | `X-SokoMail-Client: android \| ios \| web` on every request | `createDio` |
| Timeouts | Connect 10 s, receive 30 s (configurable in `AppConfig`) | `createDio` |
| Authentication | `Authorization: Bearer <token>` when `AccessTokenSource` returns a token (none in Phase 1) | `core/network/auth_interceptor.dart` |
| 401 handling | Calls the `onUnauthorized` hook (future: refresh or sign out) | `AuthInterceptor` |
| Errors | Status codes map to typed failures (below) | `core/network/dio_failure_mapper.dart` |
| Cancellation | Every `ApiClient` call accepts a `CancelToken` | `ApiClient` |

### Status code mapping

| HTTP status | Client failure | Retried automatically |
| --- | --- | --- |
| 400, 409, 422, other 4xx | `InvalidRequestFailure` | No |
| 401 | `UnauthorizedFailure` | No |
| 403 | `ForbiddenFailure` | No |
| 404 | `NotFoundFailure` | No |
| 408, 504 | `TimeoutFailure` | Yes (max 3) |
| 5xx | `ServerFailure` | Yes (max 3) |
| No connection | `NetworkFailure` | Yes (max 3) |

## To agree with the backend team

- **Authentication flow** (password vs. company SSO/OIDC) and session
  lifetime.
- **Web sessions:** HttpOnly, Secure, SameSite cookies. Requires CORS with
  `Access-Control-Allow-Credentials: true` and an explicit allowed origin
  (not `*`), plus a CSRF strategy.
- **Mobile sessions:** access/refresh token format and refresh endpoint.
- **CORS:** allow the `X-SokoMail-Client` and `Authorization` request headers
  for the web origin.
- **Error body format** (for example an error code the client can map to
  specific messages). The client currently ignores error bodies.
- **Identifiers:** opaque string IDs for users, mailboxes and messages. The
  client never uses IMAP UIDs or folder names directly; `MailFolder` values
  (`inbox`, `sent`, `drafts`, `spam`, `trash`) appear in public URLs.
- **Pagination:** cursor-based for message lists.
- **Message bodies:** plain text plus server-sanitised HTML.
- **Attachments:** download through short-lived authorised URLs or streamed
  endpoints; upload limits.
- **Permissions:** the API returns each mailbox's permissions
  (`read`, `send`, `manage`) and enforces them on every request.
- **Push notifications:** token registration endpoint; payloads must not
  contain message bodies.

## Adding an endpoint on the client

See "Integration with the Go API" in
[../architecture/overview.md](../architecture/overview.md#integration-with-the-go-api).
