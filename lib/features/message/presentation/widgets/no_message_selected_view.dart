import 'package:material_ui/material_ui.dart';
import 'package:sokomail/shared/widgets/app_empty_state.dart';

/// Reading-pane placeholder shown in two-pane layouts before a message is
/// selected.
class NoMessageSelectedView extends StatelessWidget {
  const NoMessageSelectedView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.transparent,
      body: AppEmptyState(
        icon: Icons.mark_email_read_outlined,
        title: 'No message selected',
        message: 'Choose a message from the list to read it here.',
      ),
    );
  }
}
