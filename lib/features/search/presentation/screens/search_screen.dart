import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/layout/responsive_page.dart';
import 'package:sokomail/features/search/presentation/providers/search_results_provider.dart';
import 'package:sokomail/shared/extensions/mail_folder_presentation.dart';
import 'package:sokomail/shared/models/message_summary.dart';
import 'package:sokomail/shared/widgets/app_empty_state.dart';
import 'package:sokomail/shared/widgets/app_error_view.dart';
import 'package:sokomail/shared/widgets/app_loading_indicator.dart';
import 'package:sokomail/shared/widgets/app_search_field.dart';
import 'package:sokomail/shared/widgets/message_list_tile.dart';

/// Searches the current mailbox by sender, subject and content as you type.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({
    super.key,
    required this.mailboxId,
    required this.onOpenMessage,
    this.initialQuery = '',
    this.onBack,
  });

  final String mailboxId;
  final String initialQuery;
  final ValueChanged<MessageSummary> onOpenMessage;
  final VoidCallback? onBack;

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(text: widget.initialQuery);
  late String _query = widget.initialQuery;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _query.trim();
    final results = ref.watch(
      searchResultsProvider((mailboxId: widget.mailboxId, query: query)),
    );

    final Widget body;
    if (query.isEmpty) {
      body = const AppEmptyState(
        icon: Icons.manage_search_rounded,
        title: 'Search your mail',
        message: 'Find messages by sender, subject or content.',
      );
    } else {
      body = results.when(
        skipLoadingOnReload: true,
        loading: () => const AppLoadingIndicator(),
        error: (error, _) => AppErrorView(title: 'Search failed', error: error),
        data: (messages) => messages.isEmpty
            ? AppEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No results',
                message: 'Nothing matches "$query".',
              )
            : ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                itemCount: messages.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                      child: Text(
                        '${messages.length} '
                        '${messages.length == 1 ? 'result' : 'results'}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    );
                  }
                  final message = messages[index - 1];
                  return MessageListTile(
                    key: ValueKey(message.id),
                    message: message,
                    selected: false,
                    folderLabel: message.folder.label,
                    onTap: () => widget.onOpenMessage(message),
                  );
                },
              ),
      );
    }

    return ResponsivePage(
      title: 'Search',
      onBack: widget.onBack,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: AppSearchField(
                  controller: _controller,
                  hint: 'Search by sender, subject or content',
                  autofocus: widget.initialQuery.isEmpty,
                  onChanged: (value) => setState(() => _query = value),
                  onSubmitted: (value) => setState(() => _query = value),
                ),
              ),
            ),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}
