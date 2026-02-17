class BleProtocol {
  // --- COMMAND CONSTANTS ---
  static const int cmdVerify = 0x00;
  static const int cmdGetVersion = 0x01;
  static const int cmdGetTime = 0x02;
  static const int cmdSetTime = 0x03;
  static const int cmdGetInfo = 0x08;
  static const int cmdGetStatus = 0x10;
  static const int cmdControl = 0x20;
  static const int cmdQuickStart = 0x21; // 33
  static const int cmdGetCountdown = 0x30;
  static const int cmdSetCountdown = 0x31; // 49
  static const int cmdGetBrightness = 0x40;
  static const int cmdSetBrightness = 0x41; // 65
  static const int cmdSetPulse = 0x42;      // 66
  static const int cmdSetWorkMode = 0x50;  // 80
  static const int cmdGetWorkMode = 0x51;

  // --- PACKET STRUCTURE ---
  // Header: 0x3A (:)
  // Addr:   0x01
  // Cmd:    1 byte
  // LenH:   1 byte
  // LenL:   1 byte
  // Data:   N bytes
  // Check:  1 byte
  // Footer: 0x0A (\n)

  /// Constructs a packet for the given command and payload.
  /// Mirrors the APK `doCmd` framing:
  /// `3A 01 CMD LEN_H LEN_L ...PAYLOAD CHECK 0A`.
  static List<int> buildPacket(int command, List<int> payload) {
    final normalizedPayload =
        payload.map((byte) => byte & 0xFF).toList(growable: false);
    final length = normalizedPayload.length;
    final lengthHigh = (length >> 8) & 0xFF;
    final lengthLow = length & 0xFF;

    int checksum = 0;
    checksum += 0x01; // Address
    checksum += command & 0xFF;
    checksum += lengthHigh;
    checksum += lengthLow;
    for (final byte in normalizedPayload) {
      checksum += byte;
    }
    checksum &= 0xFF;

    return <int>[
      0x3A,
      0x01,
      command & 0xFF,
      lengthHigh,
      lengthLow,
      ...normalizedPayload,
      checksum,
      0x0A,
    ];
  }

  /// Helper to create a SET BRIGHTNESS command
  /// [values] Raw brightness payload. Kept for compatibility with older calls.
  static List<int> setBrightness(List<int> values) {
    final payload = values.map((v) => v & 0xFF).toList(growable: false);
    return buildPacket(cmdSetBrightness, payload);
  }

  /// Helper to set a single brightness channel: `[channelIndex, value]`.
  static List<int> setBrightnessChannel(int channelIndex, int value) {
    final channel = channelIndex.clamp(0, 255).toInt();
    final brightness = value.clamp(0, 100).toInt();
    return buildPacket(cmdSetBrightness, [channel, brightness]);
  }

  /// Helper to Turn On/Off (using Control command 0x20?)
  /// Analysis says 0x20 is Basic Control. 
  /// Needs experimentation. Usually 0x01 = ON, 0x00 = OFF for payload.
  static List<int> setPower(bool on) {
    return buildPacket(cmdControl, [on ? 0x01 : 0x00]);
  }
  
  /// Helper to Set Work Mode (0x50)
  /// Modes might be: 0=CW, 1=Pulse, etc.
  static List<int> setWorkMode(int mode) {
    return buildPacket(cmdSetWorkMode, [mode]);
  }

  /// Helper to Set Pulse (0x42)
  /// [hz] Frequency in Hz.
  /// Update v38: Always send 2 bytes (Big Endian) to prevent 9999 error.
  static List<int> setPulse(int hz) {
    return buildPacket(cmdSetPulse, [(hz >> 8) & 0xFF, hz & 0xFF]);
  }

  /// Helper to Set Countdown (0x31)
  /// [minutes] Duration.
  /// Sends Total Seconds in Big Endian (2 bytes).
  static List<int> setCountdown(int minutes) {
    int totalSeconds = minutes * 60;
    return buildPacket(cmdSetCountdown, [(totalSeconds >> 8) & 0xFF, totalSeconds & 0xFF]);
  }
  
  /// Helper for Quick Start (0x21)
  /// [mode] 0x01 = Preset 1?, 0x00 = Manual?
  static List<int> quickStart({int mode = 0x00}) {
    return buildPacket(cmdQuickStart, [mode]);
  }

  // --- READ HELPERS ---
  static List<int> getCountdown() => buildPacket(cmdGetCountdown, []);
  static List<int> getBrightness() => buildPacket(cmdGetBrightness, []);
  static List<int> getWorkMode() => buildPacket(cmdGetWorkMode, []);
  static List<int> getStatus() => buildPacket(cmdGetStatus, []);
}
