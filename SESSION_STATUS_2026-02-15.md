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

## Continuation update (end of day)
- Current local/app state:
  - `HEAD`: `1d00336`
  - Latest successful build run: `22043106224`
  - Run URL: `https://github.com/benjamoide/megapanelAI/actions/runs/22043106224`
- User-confirmed behavior:
  - BLE protocol TX/RX path was working with correct responses on `fff1`.
  - Treatment/manual time now converges to configured value after initial transient display.
  - In the latest app version, Bluetooth scan/discovery is currently failing to find the device.
- Features added in latest commit:
  - Confirmation dialogs for plan removal and treatment registration.
  - Undo for accidental completed registration.
  - IA prompt updated to prioritize scientific sources (PubMed, ClinicalTrials, Cochrane, etc.).

## Priority for tomorrow (must follow this order)
1. Fix Bluetooth discovery first (blocker):
   - Reproduce "device not found" in scan dialog.
   - Verify scan filters and BLE permissions at runtime.
   - Compare discovery path against last known working behavior and patch with minimal scope.
   - Ship a test APK and confirm device appears and connects.
2. After BLE scan is stable, run scientific audit of current treatment database:
   - Treatment-by-treatment review using requested evidence sources.
   - For each treatment define: wavelength percentages per available channel, pulse/CW and frequency, duration, distance, indications, and contraindications.
   - Mark confidence/evidence strength and identify items requiring conservative defaults.

## Continuation update (2026-02-16)
- Priority 1 progress (BLE discovery blocker):
  - Implemented a minimal scan-path patch focused only on discovery reliability.
  - Updated `lib/bluetooth/ble_manager.dart`:
    - `init()` now requests core BLE permissions (`bluetoothScan`, `bluetoothConnect`) without gating on location.
    - `startScan()` now:
      - requires only BLE scan/connect permissions to proceed;
      - treats location as optional and passes `androidUsesFineLocation` dynamically;
      - starts scanning without a fixed timeout (dialog lifecycle still stops scan on close).
  - Updated `lib/main.dart` (`BluetoothScanDialog`):
    - Removed hard exclusion of scan results with empty `device.platformName`.
    - Added display-name fallback order: `advertisementData.advName` -> `device.platformName` -> `"Dispositivo sin nombre"`.
    - Kept strict default filter (`block/panel/mega`) but now evaluated on fallback display name.
    - Connected-device title now falls back to `remoteId` if name is empty.
    - Connection success snackbar now uses the same fallback display name.

## Immediate validation required on hardware
1. Open scan dialog and confirm device appears within 5-20s without enabling debug list.
2. If not visible, tap "Mostrar todos (Debug)" and verify whether unnamed devices now appear.
3. Connect and verify BLE command path still works (RUN/STOP and at least one dimming update).
4. Capture logs from manual debug view and compare with prior known-good TX/RX behavior.

## If scan still fails after this patch
1. Capture runtime permission statuses and location service state on the test phone.
2. Add temporary scan telemetry logs per result (`remoteId`, `advName`, `platformName`, `rssi`).
3. Compare Android SDK/device model behavior against last known working APK build.

## Continuation update (2026-02-16 - scientific audit)
- Created full treatment-by-treatment scientific audit:
  - File: `AUDITORIA_CIENTIFICA_TRATAMIENTOS_2026-02-16.md`
  - Coverage: 29/29 base treatments from `DB_DEFINICIONES`.
  - Includes for each treatment:
    - percentage per available wavelength (630/660/810/830/850),
    - pulse/CW mode and frequency recommendation,
    - duration and distance,
    - indications and contraindications,
    - evidence/confidence level.
- Sources prioritized:
  - PubMed systematic reviews/meta-analyses and RCTs,
  - WALT dosage recommendation page for PBM dosing reference.

## Continuation update (2026-02-16 - audit applied to app values)
- Applied scientific audit to `DB_DEFINICIONES` in `lib/main.dart`:
  - Standardized each treatment to 5-channel percentages (`630/660/810/830/850`).
  - Updated mode/frequency to conservative `CW` baseline for all catalog entries.
  - Updated default duration and distance-oriented positioning text per treatment.
  - Added/updated contraindication notes in `prohibidos` for each treatment.
- Status:
  - Catalog values are now aligned with the evidence-based matrix from `AUDITORIA_CIENTIFICA_TRATAMIENTOS_2026-02-16.md`.

## Continuation update (2026-02-16 - workflow + github sync)
- Current local/app state:
  - Branch: `main`
  - `HEAD`: `a53e9ef`
  - Last functional changes commit: `eee3ff0` (`Apply scientific audit values and stabilize BLE discovery`)
  - CI workflow commit: `a53e9ef` (`Add Flutter CI workflow`)
- GitHub sync:
  - Pushed to `origin/main` successfully (`1d00336..a53e9ef`).
- Workflows status after push:
  - `Deploy Web & Android`: `success`
    - Run: `22076676283`
    - URL: `https://github.com/benjamoide/megapanelAI/actions/runs/22076676283`
  - `Flutter CI`: `failure` in `Analyze`
    - Run: `22076676254`
    - URL: `https://github.com/benjamoide/megapanelAI/actions/runs/22076676254`
    - Cause: `flutter analyze` returns non-zero due lints/info/warnings (29 issues), so `Test` and `Build APK` were skipped in that workflow.

## Exact resume point for tomorrow
1. Open failing CI run `22076676254` and confirm analyzer output is unchanged.
2. Decide CI policy (pick one and implement):
   - A) Keep strict analyze and fix lints in code.
   - B) Keep current code and relax CI analyze gate (e.g., warnings-only strategy).
3. If choosing A (recommended for long-term quality):
   - Start with low-risk issues first:
     - remove unused import in `lib/views/bluetooth_custom_view.dart`,
     - add braces for single-line `if` blocks flagged in `lib/main.dart`,
     - address easy `const` suggestions.
   - Re-run workflow via push (or local analyze if environment allows).
4. Re-verify BLE on hardware after CI pass:
   - scan visibility,
   - connect,
   - run/stop and dimming update path.
5. If BLE behavior is stable, move to phase 2:
   - fine-tune treatment wording/contraindications in UI text and publish v52 build.
