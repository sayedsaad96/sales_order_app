import 'dart:async';
import 'package:flutter/foundation.dart';

/// Performance utility functions for optimizing Flutter app performance
class PerformanceUtils {
  /// Debounces a function call by [duration]
  /// Useful for search inputs to avoid excessive rebuilds
  static Timer? _debounceTimer;

  static void debounce({
    required Duration duration,
    required VoidCallback action,
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(duration, action);
  }

  /// Cancels any pending debounced actions
  static void cancelDebounce() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
  }

  /// Throttles a function call to execute at most once per [duration]
  static DateTime? _lastThrottleTime;

  static void throttle({
    required Duration duration,
    required VoidCallback action,
  }) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) >= duration) {
      _lastThrottleTime = now;
      action();
    }
  }
}
