import 'package:material_ui/material_ui.dart';

/// Short-hands for reading the current theme.
extension BuildContextTheme on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;
}
