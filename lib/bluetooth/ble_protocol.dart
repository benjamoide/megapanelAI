
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
  static List<int> buildPacket(int command, List<int> payload) {
    List<int> packet = [];
    
    // Header & Address
    packet.add(0x3A); // ':'
    packet.add(0x01); // Address
    
    // Command
    packet.add(command);
    
    // Length (Big Endian based on analysis e.length / 256)
    int len = payload.length;
    packet.add((len >> 8) & 0xFF); // High byte
    packet.add(len & 0xFF);        // Low byte
    
    // Payload
    packet.addAll(payload);
    
    // Checksum: Sum of bytes from Index 1 to End-2 (Address...Data) % 256
    int sum = 0;
    // We sum from index 1 (Address) up to the last data byte
    for (int i = 1; i < packet.length; i++) {
      sum += packet[i];
    }
    int checksum = sum % 256;
    packet.add(checksum);
    
    // Footer
    packet.add(0x0A); // '\n'
    
    return packet;
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
