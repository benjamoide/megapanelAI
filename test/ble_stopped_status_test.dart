import 'package:flutter_test/flutter_test.dart';
import 'package:mega_panel_ai/bluetooth/ble_protocol.dart';

void main() {
  final stopped = <int>[
    0x2a, 1, 0x10, 0, 5, 0, 2, 0x58, 2, 0x58, 0xca, 10,
  ];
  test('captured stopped status permits skipping pre-start OFF', () {
    expect(BleProtocol.isStoppedStatus(stopped), isTrue);
  });
  test('running status never permits skipping OFF', () {
    final running = [...stopped]..[5] = 1;
    running[10] = 0xcb;
    expect(BleProtocol.isStoppedStatus(running), isFalse);
  });
  test('silence, ACK and incomplete status cannot establish stopped', () {
    for (final frame in <List<int>>[
      [],
      [0x2a, 1, 0x20, 0, 0, 0x21, 10],
      stopped.sublist(0, 6),
    ]) {
      expect(BleProtocol.isStoppedStatus(frame), isFalse);
    }
  });
  test('corrupt or unrelated responses never establish stopped', () {
    for (final index in [0, 1, 2, 3, 4, 10, 11]) {
      final corrupt = [...stopped];
      corrupt[index] ^= 0x40;
      expect(BleProtocol.isStoppedStatus(corrupt), isFalse);
    }
  });
}
