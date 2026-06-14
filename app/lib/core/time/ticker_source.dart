/// Abstraction over wall-clock reads.
///
/// M1's anchor-based timer engine derives remaining time from
/// `endsAt - now()` rather than counting ticks, so injecting a fake
/// [TickerSource] makes the whole engine deterministic under test.
abstract class TickerSource {
  DateTime now();
}

/// Production source — the device clock.
class SystemTickerSource implements TickerSource {
  const SystemTickerSource();

  @override
  DateTime now() => DateTime.now();
}
