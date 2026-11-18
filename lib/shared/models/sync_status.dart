/// Synchronisation state of locally cached mail data.
///
/// Reserved for the offline-storage milestone (Drift/SQLite). Phase 1 does
/// not cache or synchronise mail; see docs/architecture/overview.md.
enum SyncStatus {
  /// Nothing has been cached for this item yet.
  notSynced,

  /// A sync with the Go API is in progress.
  syncing,

  /// The local copy matches the server as of the last sync.
  synced,

  /// The device is offline; cached data may be stale.
  offline,

  /// The last sync attempt failed.
  failed,
}
