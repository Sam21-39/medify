/// The only sync state the UI ever sees — never raw queue internals
/// (Section 6.1). Rendered as a passive status indicator, never a blocking
/// dependency, consistent with the local-first principle.
enum SyncStatus { syncing, synced, offlineWillSyncLater }
