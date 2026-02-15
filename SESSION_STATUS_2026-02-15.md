# Session Status - 2026-02-15

## Goal
Replicate BlueLight APK BLE behavior in Flutter app (`mega_panel_ai`) to reliably set wavelengths, pulse mode/frequency, and treatment duration.

## What was confirmed
- BlueLight app protocol frame matches current Dart design:
  - Header: `0x3A`
  - Address: `0x01`
  - Command: 1 byte
  - Length: 2 bytes (big-endian)
  - Payload: N bytes
  - Checksum: sum(bytes from address to payload) % 256 (signed in JS via `intToByte`)
  - Footer: `0x0A`
- Command IDs found in decompiled `app-service.js` align with `lib/bluetooth/ble_protocol.dart`:
  - `0x20` control on/off
  - `0x21` quick start
  - `0x31` set countdown
  - `0x41` set brightness
  - `0x42` set pulse
  - `0x50` set work mode
  - plus read commands (`0x10`, `0x30`, `0x40`, `0x51`, etc.)

## BLE connection behavior observed in BlueLight
- No fixed service/characteristic UUID hardcoded in plain text was found.
- The app discovers services/characteristics dynamically and assigns:
  - `qU` = selected `serviceId`
  - `$U` = selected notify characteristic UUID
  - `jU` = selected write characteristic UUID
- Selection appears to be based on characteristic properties (`notify`, `write`) after `getBLEDeviceServices` + `getBLEDeviceCharacteristics`.

## Relevant local code in this project
- Packet protocol builder: `lib/bluetooth/ble_protocol.dart`
- BLE manager connection/discovery/write: `lib/bluetooth/ble_manager.dart`
- Treatment start flow: `lib/main.dart` (`iniciarCiclo`, `iniciarCicloManual`, `_sendParameters`)
- Manual BLE UI/debug panel: `lib/views/bluetooth_custom_view.dart`

## Current gap
- We still need a cleaner extraction of exact BlueLight runtime sequence timing/order under each screen action (RUN, DIMMING, PULSE, TIME), though protocol + command map are already aligned.

## Next steps for tomorrow
1. Extract concise snippets from decompiled `app-service.js` around:
   - `sendInitData`
   - `sendData`
   - write queue/chunk logic
   - ACK/response parser
2. Mirror BlueLight exact order in Flutter:
   - likely `setWorkMode` -> `setBrightness` -> `setCountdown` -> `setPulse` -> `quickStart` (verify with extracted snippets)
3. Patch Flutter BLE layer with same retry/timing strategy as APK.
4. Validate on hardware with log comparison (TX/RX hex side-by-side).

## Notes
- Decompile paths used:
  - `C:\Users\bherr\Downloads\megapanel app\decompile\Resources`
  - `C:\Users\bherr\Downloads\megapanel app\decompile\Sources`
- Main decompiled file analyzed:
  - `C:\Users\bherr\Downloads\megapanel app\decompile\Resources\assets\apps\__UNI__F86FA96\www\app-service.js`

## Continuation update (same day)
- Extracted additional decompiled snippets confirming:
  - `sendData` chunks outgoing payloads in blocks of 20 bytes.
  - BLE writes are serialized and retried.
  - Service/characteristic selection prefers a service exposing both write + notify.
  - Init/runtime handlers route command ACKs through `handlerCmd`.
- Patched Flutter code:
  - `lib/bluetooth/ble_protocol.dart`
    - Removed payload/checksum byte sanitization logic.
    - Kept packet framing/checksum aligned to APK `doCmd`.
    - Added `setBrightnessChannel(channel, value)` helper.
  - `lib/bluetooth/ble_manager.dart`
    - Added service+characteristic pairing logic (prefer same service with write+notify).
    - Added queued write path, 20-byte chunking, retry loop, and hex TX/RX logging.
  - `lib/main.dart`
    - Replaced experimental v4x/v5x send flow with deterministic sequence:
      - `setWorkMode` -> per-channel `setBrightnessChannel` -> `setCountdown` -> `setPulse`
      - followed by start command (`quickStart` or `setPower(true)` in manual mode).

## Remaining validation
1. Hardware test the new sequence (catalog and manual flows).
2. Compare Flutter TX/RX logs against APK side-by-side for:
   - channel update behavior
   - pulse apply behavior
   - run/stop behavior
3. If needed, tune per-command delays and `0x20` payload semantics on-device.
