import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sokomail/core/storage/preferences_store.dart';

/// Whether the desktop sidebar is collapsed to icons. Saved on the device.
final sidebarCollapsedProvider =
    NotifierProvider<SidebarCollapsedController, bool>(
      SidebarCollapsedController.new,
    );

class SidebarCollapsedController extends Notifier<bool> {
  @override
  bool build() =>
      ref
          .watch(preferencesStoreProvider)
          .readString(PreferenceKeys.sidebarCollapsed) ==
      'true';

  Future<void> toggle() async {
    state = !state;
    await ref
        .read(preferencesStoreProvider)
        .writeString(PreferenceKeys.sidebarCollapsed, '$state');
  }
}

/// Whether the tablet sidebar is expanded. Tablets start with the compact
/// icon rail so both mail panes fit; the choice lasts for the session.
final tabletSidebarExpandedProvider =
    NotifierProvider<TabletSidebarController, bool>(
      TabletSidebarController.new,
    );

class TabletSidebarController extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}
