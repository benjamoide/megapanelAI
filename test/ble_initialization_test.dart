import 'package:flutter_test/flutter_test.dart';
import 'package:mega_panel_ai/bluetooth/ble_protocol.dart';
import 'package:mega_panel_ai/bluetooth/official_initialization.dart';

void main() {
  test('official init tolerates absent 52 ACK and never sends a start or stop',
      () async {
    final writes = <List<int>>[];
    final ok = await initializeOfficialPanel(
      checkCancelled: () {},
      exchange: (packet, command, timeout) async {
        writes.add(packet);
        if (command == 0x52) {
          expect(timeout, const Duration(milliseconds: 200));
          return null;
        }
        return BleProtocol.buildPacket(command, []);
      },
    );
    expect(ok, isTrue);
    expect(writes.map((p) => p[2]).toList(),
        [0x52, 0x74, 0x74, 0x74, 0x74, 0x31,
         0x41, 0x41, 0x41, 0x41, 0x41, 0x75, 0x42, 0x75]);
    expect(writes.any((p) => [0x20, 0x21, 0x73].contains(p[2])), isFalse);
  });

  test('missing final preset response prevents initialization completion',
      () async {
    final commands = <int>[];
    final ok = await initializeOfficialPanel(
      checkCancelled: () {},
      exchange: (packet, command, timeout) async {
        final afterPulse = commands.contains(0x42);
        commands.add(command);
        if (command == 0x75 && afterPulse) {
          expect(packet, BleProtocol.getCurrentPreset());
          expect(timeout, const Duration(milliseconds: 1600));
          return null;
        }
        return BleProtocol.buildPacket(command, []);
      },
    );
    expect(ok, isFalse);
    expect(commands.sublist(commands.length - 3), [0x75, 0x42, 0x75]);
  });

  test('silent panel stops after first preset, without writing brightness',
      () async {
    final commands = <int>[];
    final ok = await initializeOfficialPanel(
      checkCancelled: () {},
      exchange: (packet, command, timeout) async {
        commands.add(command);
        return null;
      },
    );
    expect(ok, isFalse);
    expect(commands, [0x52, 0x74]);
  });

  test('missing later ACK stops the chain immediately', () async {
    final commands = <int>[];
    final ok = await initializeOfficialPanel(
      checkCancelled: () {},
      exchange: (packet, command, timeout) async {
        commands.add(command);
        if (command == 0x52 || command == 0x31) return null;
        return BleProtocol.buildPacket(command, []);
      },
    );
    expect(ok, isFalse);
    expect(commands, [0x52, 0x74, 0x74, 0x74, 0x74, 0x31]);
  });

  test('stop or disconnect cancellation prevents further writes', () async {
    final commands = <int>[];
    await expectLater(
      initializeOfficialPanel(
        checkCancelled: () {
          if (commands.isNotEmpty) throw StateError('cancelled');
        },
        exchange: (packet, command, timeout) async {
          commands.add(command);
          return null;
        },
      ),
      throwsStateError,
    );
    expect(commands, [0x52]);
  });

  test('seven-channel response configures all seven channels', () async {
    final channels = <int>[];
    expect(await initializeOfficialPanel(
      checkCancelled: () {},
      exchange: (packet, command, timeout) async {
        if (command == 0x52) {
          return BleProtocol.buildPacket(command, [0, 1, 2, 3, 4, 5, 6]);
        }
        if (command == 0x41) channels.add(packet[5]);
        return BleProtocol.buildPacket(command, []);
      },
    ), isTrue);
    expect(channels, [0, 1, 2, 3, 4, 5, 6]);
  });
}
