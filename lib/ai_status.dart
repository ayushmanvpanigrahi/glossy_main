import 'package:flutter/foundation.dart';

/// Global AI status notifier.
/// 'inactive' | 'checking' | 'active'
final aiStatusNotifier = ValueNotifier<String>('inactive');