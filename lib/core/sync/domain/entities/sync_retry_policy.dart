import 'dart:math';

class SyncRetryPolicy {
  SyncRetryPolicy({
    this.maxAttempts = 5,
    this.initialDelay = const Duration(seconds: 5),
    this.maxDelay = const Duration(minutes: 30),
  });

  final int maxAttempts;
  final Duration initialDelay;
  final Duration maxDelay;

  Duration getDelay(int attemptCount) {
    final exponent = max(0, attemptCount - 1);
    final multiplier = pow(2, exponent).toInt();

    final delayMilliseconds = initialDelay.inMilliseconds * multiplier;

    final cappedMilliseconds = min(delayMilliseconds, maxDelay.inMilliseconds);

    // Add up to 20% jitter to avoid synchronized retries.
    final jitter = Random.secure().nextDouble() * 0.2;

    return Duration(milliseconds: (cappedMilliseconds * (1 + jitter)).round());
  }
}
