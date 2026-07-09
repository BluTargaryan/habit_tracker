import 'dart:math';

String generateId() {
  final random = Random.secure();
  final timestamp = DateTime.now().microsecondsSinceEpoch;
  final suffix = random.nextInt(1 << 32);
  return '$timestamp-$suffix';
}
