# notifications (planned)

No code yet: Phase 1 deliberately adds no Firebase or push dependencies.

Planned responsibilities for the notifications milestone:

- Request notification permission at a meaningful moment (not on first launch).
- Obtain a push token (FCM on Android, APNs on iOS, Web Push on the web) and
  register it with the SokoMail Go API for the signed-in employee.
- Unregister the token on sign-out.
- Handle notification taps by navigating to `/mail/:mailboxId/messages/:id`.
- Notification payloads must not contain message bodies; show sender and
  subject only if company policy allows, otherwise a generic "New message".

Expected structure when implemented:

```text
notifications/
├── data/          # token registration through the API client
├── domain/        # NotificationPreferences, PushRegistration
└── presentation/  # settings section, permission prompts
```
