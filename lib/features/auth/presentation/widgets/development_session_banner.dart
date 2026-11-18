import 'package:material_ui/material_ui.dart';
import 'package:sokomail/app/theme/app_colors.dart';

/// Persistent strip shown while a development session is active, so the
/// unauthenticated state and sample data are never mistaken for real mail.
class DevelopmentSessionBanner extends StatelessWidget {
  const DevelopmentSessionBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.statusColors;
    final style = Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: status.onWarning);

    return Material(
      color: status.warning,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          child: Row(
            children: [
              Icon(Icons.science_outlined, size: 16, color: status.onWarning),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Development session - not authenticated by a server. '
                  'Sample data only; changes are local to this session.',
                  style: style,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
