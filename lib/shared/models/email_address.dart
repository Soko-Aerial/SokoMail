import 'package:flutter/foundation.dart';

/// An email address with an optional display name.
@immutable
class EmailAddress {
  const EmailAddress(this.address, {this.displayName});

  final String address;
  final String? displayName;

  /// The display name when available, otherwise the address.
  String get label {
    final name = displayName?.trim();
    return name == null || name.isEmpty ? address : name;
  }

  // Pragmatic syntax check for form feedback only. The server performs the
  // authoritative validation before any message is sent.
  static final _pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static bool isValid(String value) => _pattern.hasMatch(value.trim());

  @override
  bool operator ==(Object other) =>
      other is EmailAddress &&
      other.address.toLowerCase() == address.toLowerCase() &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(address.toLowerCase(), displayName);

  @override
  String toString() => 'EmailAddress($label)';
}
