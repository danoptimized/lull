import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The current *local* wall-clock time, for surfaces that show a time-of-day
/// greeting or the local date (e.g. the Today header).
///
/// Read through this provider rather than calling [DateTime.now] inline so
/// goldens and tests can pin "now" to a fixed instant and render
/// deterministically. It yields a *function*, not a value, so each read
/// re-evaluates: in the app it tracks the real clock exactly as `DateTime.now`
/// did; an override can return a constant.
final wallClockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
