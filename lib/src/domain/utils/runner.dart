import 'dart:async';

class Runner {
  
  bool _active = false;
  bool _disposed = false;

  Duration frequency;
  Future<void> Function() callback;
  Future<void> Function(Object?)? callbackError;

  Runner._({
    required this.frequency,
    required this.callback,
    this.callbackError,
  });

  factory Runner({
    required Duration frequency,
    required Future<void> Function() callback,
    Future<void> Function(Object?)? callbackError,
  }) {
    final instance = Runner._(
      frequency: frequency,
      callback: callback,
      callbackError: callbackError,
    );
    instance._run();
    return instance;
  }

  void _run() async {
    if (_active) {
      try {
        await callback();
      } catch (err) {
        try {
          if (callbackError != null) await callbackError!(err);
        } catch (_) {}
      }
    }
    await Future.delayed(frequency);
    if (_disposed) return;
    Timer.run(_run);
  }

  void start() => _active = true;

  void stop() => _active = false;

  /// Encerra de vez: além de parar, não reagenda mais a execução.
  void dispose() {
    _disposed = true;
    _active = false;
  }

  bool get active => _active;
}