import 'ble_protocol.dart';

typedef InitExchange = Future<List<int>?> Function(
    List<int> packet, int command, Duration timeout);

/// Configuration only: never sends control, quick-start or run-preset commands.
Future<bool> initializeOfficialPanel({
  required InitExchange exchange,
  required void Function() checkCancelled,
}) async {
  Future<List<int>?> send(List<int> packet, Duration timeout) {
    checkCancelled();
    return exchange(packet, packet[2], timeout);
  }

  final mode = await send(
    BleProtocol.getModeChannels(0),
    const Duration(milliseconds: 200),
  );
  final channels = mode == null || mode.length < 7
      ? 5
      : ((mode[3] << 8) | mode[4]).clamp(5, 7).toInt();
  final packets = <List<int>>[
    for (var i = 0; i < 4; i++)
      BleProtocol.renamePreset(i, 'Custom ${i + 1}'),
    BleProtocol.setCountdownSeconds(1200),
    for (var i = 0; i < channels; i++)
      BleProtocol.setBrightnessChannel(i, 100),
    BleProtocol.getCurrentPreset(),
    BleProtocol.setPulse(0),
  ];
  // Only 0x52 may lack an ACK. Do not flood a silent panel with later settings.
  for (final packet in packets) {
    if (await send(packet, const Duration(milliseconds: 1600)) == null) {
      return false;
    }
  }
  checkCancelled();
  return true;
}
