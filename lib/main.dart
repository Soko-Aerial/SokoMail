import 'dart:async';

import 'package:sokomail/bootstrap.dart';

/// Entry point for Android, iOS and Web.
///
/// Configuration is supplied with `--dart-define` (see README.md); there is
/// one entry point for every environment.
void main() => unawaited(bootstrap());
