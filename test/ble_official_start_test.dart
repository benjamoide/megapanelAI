import 'package:flutter_test/flutter_test.dart';
import 'package:mega_panel_ai/bluetooth/ble_protocol.dart';
import 'package:mega_panel_ai/bluetooth/official_start.dart';

void main() {
  final running = <int>[
    0x2a, 1, 0x10, 0, 5, 1, 4, 0xb0, 4, 0xb0, 0x7f, 0x0a,
  ];

  test('start matches the successful official HCI payload in one write', () {
    expect(BleProtocol.officialStart(), [
      0x3a, 1, 0x20, 0, 1, 1, 0x23, 0x0a,
      0x3a, 1, 0x20, 0, 1, 2, 0x24, 0x0a,
    ]);
    expect(BleProtocol.officialStart().length, lessThanOrEqualTo(20));
    expect(BleProtocol.setPower(false),
        [0x3a, 1, 0x20, 0, 1, 0, 0x22, 0x0a]);
  });

  test('only running status confirms start, not ACK, stopped or truncated', () {
    expect(BleProtocol.isRunningStatus(running), isTrue);
    expect(BleProtocol.isRunningStatus([...running]..[5] = 0), isFalse);
    expect(BleProtocol.isRunningStatus([0x2a, 1, 0x20, 0, 0, 0x21, 10]),
        isFalse);
    expect(BleProtocol.isRunningStatus(running.sublist(0, 6)), isFalse);
  });

  test('subscribes before the atomic start and never sends a second latch',
      () async {
    final writes = <List<int>>[];
    var subscribed = false;
    await sendOfficialStart(
      write: (packet) async {
        expect(subscribed, isTrue);
        writes.add(packet);
      },
      waitForRunning: () async {
        subscribed = true;
        return running;
      },
      checkAbort: () {},
      delay: (_) async {},
    );
    expect(writes, [BleProtocol.officialStart(), BleProtocol.getStatus()]);
  });

  test('missing running notification stops without quickstart or retry',
      () async {
    final writes = <List<int>>[];
    await expectLater(
      sendOfficialStart(
        write: (packet) async => writes.add(packet),
        waitForRunning: () async => null,
        checkAbort: () {},
        delay: (_) async {},
      ),
      throwsStateError,
    );
    expect(writes, [
      BleProtocol.officialStart(),
      BleProtocol.getStatus(),
      BleProtocol.setPower(false),
    ]);
  });

  test('abort before start writes nothing', () async {
    final writes = <List<int>>[];
    await expectLater(
      sendOfficialStart(
        write: (packet) async => writes.add(packet),
        waitForRunning: () async => running,
        checkAbort: () => throw StateError('aborted'),
        delay: (_) async {},
      ),
      throwsStateError,
    );
    expect(writes, isEmpty);
  });

  test('abort after start sends stop, not another start', () async {
    final writes = <List<int>>[];
    var checks = 0;
    await expectLater(
      sendOfficialStart(
        write: (packet) async => writes.add(packet),
        waitForRunning: () async => running,
        checkAbort: () {
          if (++checks > 1) throw StateError('aborted');
        },
        delay: (_) async {},
      ),
      throwsStateError,
    );
    expect(writes, [BleProtocol.officialStart(), BleProtocol.setPower(false)]);
  });
}
