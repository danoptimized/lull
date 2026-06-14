/// Domain-level failures. Foundation for later milestones; M0 ships mock
/// data only, so nothing throws these yet.
///
/// Messages follow the lull voice: lowercase, brief, kind — they may be
/// shown to the user verbatim.
sealed class Failure {
  const Failure(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Anything we did not anticipate. The catch-all at seam boundaries.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'something went wrong']);
}

/// Connectivity or server trouble.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = "couldn't reach the quiet place"]);
}

/// User input that cannot be accepted as-is.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}
