
import 'dart:typed_data';

class BleProtocol {
  // --- COMMAND CONSTANTS ---
  static const int CMD_VERIFY = 0x00;
  static const int CMD_GET_VERSION = 0x01;
  static const int CMD_GET_TIME = 0x02;
  static const int CMD_SET_TIME = 0x03;
  static const int CMD_GET_INFO = 0x08;
  static const int CMD_GET_STATUS = 0x10;
  static const int CMD_CONTROL = 0x20;
  static const int CMD_QUICK_START = 0x21; // 33
  static const int CMD_GET_COUNTDOWN = 0x30;
  static const int CMD_SET_COUNTDOWN = 0x31; // 49
  static const int CMD_GET_BRIGHTNESS = 0x40;
  static const int CMD_SET_BRIGHTNESS = 0x41; // 65
  static const int CMD_SET_PULSE = 0x42;      // 66
  static const int CMD_SET_WORK_MODE = 0x50;  // 80
  static const int CMD_GET_WORK_MODE = 0x51;

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
  /// Update v40: "The Floor is Lava".
  /// Forbidden bytes: 0x0A (10), 0x3A (58), 0x3B (59).
  /// These act as framing/delimiters and must NOT appear in Payload OR Checksum.
  static List<int> buildPacket(int command, List<int> payload) {
    List<int> packet = [];
    
    // Header & Address
    packet.add(0x3A); // ':'
    packet.add(0x01); // Address
    
    // Command
    packet.add(command);
    
    // 1. Initial Sanitize of Payload
    List<int> safePayload = payload.map((b) => _sanitizeByte(b)).toList();
    
    // 2. Calculate Checksum & Ensure Checksum itself is safe
    // If checksum matches a forbidden byte, we must tweak the payload to change the sum.
    int checksum = _calculateChecksum(packet, safePayload);
    
    // Retry loop: If checksum is forbidden, tweak the last byte of payload
    int attempts = 0;
    while (_isForbidden(checksum) && attempts < 5 && safePayload.isNotEmpty) {
      // Modify last byte by +1 (wrapping at 100 for brightness, or 255 generic)
      // For general safety, just +1. 
      int last = safePayload.last;
      safePayload[safePayload.length - 1] = _sanitizeByte(last + 1);
      
      // Recalculate
      checksum = _calculateChecksum(packet, safePayload);
      attempts++;
    }

    // Length (Big Endian)
    int len = safePayload.length;
    packet.add((len >> 8) & 0xFF); // High byte
    packet.add(len & 0xFF);        // Low byte
    
    // Payload
    packet.addAll(safePayload);
    
    // Checksum
    packet.add(checksum);
    
    // Footer
    packet.add(0x0A); // '\n'
    
    return packet;
  }

  static bool _isForbidden(int b) {
    return b == 0x0A || b == 0x3A || b == 0x3B;
  }

  static int _sanitizeByte(int b) {
    // Wrap around 255
    b = b & 0xFF; 
    if (b == 0x0A) return 0x0B; // 10 -> 11
    if (b == 0x3A) return 0x3C; // 58 -> 60 (Skip 59)
    if (b == 0x3B) return 0x3C; // 59 -> 60
    return b;
  }

  static int _calculateChecksum(List<int> header, List<int> payload) {
     int sum = 0;
     // Sum Header (skipping index 0 which is 0x3A)
     // Header currently: [3A, 01, Cmd]
     // We sum from Index 1? 
     // Code review: Original loop `for (int i = 1; i < packet.length; i++)`
     // Previous `packet` contained: [3A, 01, Cmd, LenH, LenL, Payload...]
     // Re-simulating the exact structure for sum:
     
     // 1. Address
     sum += header[1];
     // 2. Command
     sum += header[2];
     // 3. Length (Calculated from current payload)
     int len = payload.length;
     sum += (len >> 8) & 0xFF;
     sum += len & 0xFF;
     // 4. Payload
     for (int b in payload) sum += b;

     return sum % 256;
  }

  /// Helper to create a SET BRIGHTNESS command
  /// [values] List of brightness values for each channel (0-100).
  static List<int> setBrightness(List<int> values) {
    // Clamp all values to 0-100
    List<int> payload = values.map((v) => v.clamp(0, 100).toInt()).toList();
    return buildPacket(CMD_SET_BRIGHTNESS, payload);
  }

  /// Helper to Turn On/Off (using Control command 0x20?)
  /// Analysis says 0x20 is Basic Control. 
  /// Needs experimentation. Usually 0x01 = ON, 0x00 = OFF for payload.
  static List<int> setPower(bool on) {
    return buildPacket(CMD_CONTROL, [on ? 0x01 : 0x00]);
  }
  
  /// Helper to Set Work Mode (0x50)
  /// Modes might be: 0=CW, 1=Pulse, etc.
  static List<int> setWorkMode(int mode) {
    return buildPacket(CMD_SET_WORK_MODE, [mode]);
  }

  /// Helper to Set Pulse (0x42)
  /// [hz] Frequency in Hz.
  /// Update v38: Always send 2 bytes (Big Endian) to prevent 9999 error.
  static List<int> setPulse(int hz) {
    return buildPacket(CMD_SET_PULSE, [(hz >> 8) & 0xFF, hz & 0xFF]);
  }

  /// Helper to Set Countdown (0x31)
  /// [minutes] Duration.
  /// Sends Total Seconds in Big Endian (2 bytes).
  static List<int> setCountdown(int minutes) {
    int totalSeconds = minutes * 60;
    return buildPacket(CMD_SET_COUNTDOWN, [(totalSeconds >> 8) & 0xFF, totalSeconds & 0xFF]);
  }
  
  /// Helper for Quick Start (0x21)
  /// [mode] 0x01 = Preset 1?, 0x00 = Manual?
  static List<int> quickStart({int mode = 0x00}) {
    return buildPacket(CMD_QUICK_START, [mode]);
  }

  // --- READ HELPERS ---
  static List<int> getCountdown() => buildPacket(CMD_GET_COUNTDOWN, []);
  static List<int> getBrightness() => buildPacket(CMD_GET_BRIGHTNESS, []);
  static List<int> getWorkMode() => buildPacket(CMD_GET_WORK_MODE, []);
  static List<int> getStatus() => buildPacket(CMD_GET_STATUS, []);
}
