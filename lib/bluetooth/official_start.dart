import 'ble_protocol.dart';

/// One captured start transaction, with no preset or wake-edge fallbacks.
Future<void> sendOfficialStart({
  required Future<void> Function(List<int>) write,
  required Future<List<int>?> Function() waitForRunning,
  required void Function() checkAbort,
  Future<void> Function(Duration)? delay,
}) async {
  checkAbort();
  final running = waitForRunning();
  try {
    await write(BleProtocol.officialStart());
    await (delay ?? Future<void>.delayed)(const Duration(milliseconds: 300));
    checkAbort();
    await write(BleProtocol.getStatus());
    if (await running == null) {
      throw StateError('Panel did not confirm running status');
    }
    checkAbort();
  } catch (_) {
    await write(BleProtocol.setPower(false));
    rethrow;
  }
}
