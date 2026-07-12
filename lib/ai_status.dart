import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Global AI status notifier.
// Listen to this in any widget that needs to reflect the live AI key status.
// Values: 'inactive' | 'checking' | 'active'
// ---------------------------------------------------------------------------

final ValueNotifier<String> aiStatusNotifier = ValueNotifier<String>(
  'inactive',
);
