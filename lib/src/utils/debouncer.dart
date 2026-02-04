import 'dart:async';

class Debouncer {
  Debouncer({required this.duration});

  final Duration duration;
  Timer? _timer;

  void run(void Function() cb) {
    _timer?.cancel();
    _timer = Timer(duration, cb);
  }
}
