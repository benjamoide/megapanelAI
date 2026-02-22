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

## Continuation update (2026-02-17 - CI policy decision + green pipeline)
- Decision taken: **Option A** (keep strict `flutter analyze` and fix lints in code).
- Implemented fixes:
  - Removed unused import and applied `super.key` in `lib/views/bluetooth_custom_view.dart`.
  - Replaced `print` logging with `developer.log` in `lib/bluetooth/ble_manager.dart`.
  - Renamed BLE protocol command constants to lowerCamelCase in `lib/bluetooth/ble_protocol.dart`.
  - Fixed `curly_braces_in_flow_control_structures`, `prefer_const_constructors`, and spread/toList issues in `lib/main.dart`.
  - Added minimal smoke test `test/smoke_test.dart` because CI `flutter test` failed when no `test/` directory existed.
- Push/CI sequence:
  - Commit `e984b8c`: lint cleanup baseline.
  - Commit `aa53026`: final `if` block analyzer fix.
  - Commit `e90c420`: add smoke test for CI.
  - `Flutter CI` final green run: `22102113155`
    - URL: `https://github.com/benjamoide/megapanelAI/actions/runs/22102113155`
  - `Deploy Web & Android` green run for same push: `22102113116`
    - URL: `https://github.com/benjamoide/megapanelAI/actions/runs/22102113116`

## New exact resume point
1. Validate BLE on real hardware:
   - scan visibility,
   - connect,
   - run/stop command behavior,
   - dimming updates.
2. If BLE behavior is stable, continue to final wording/protocol tuning for v52 publish.

## Continuation update (2026-02-20 - hierarchy + deploy successful)
- Requested UI/data change applied in `lib/main.dart`:
  - Keep treatment groups 1-5 as previously organized.
  - Reworked group 6 to zone-first hierarchy with treatment type inside each zone.
  - Group 6 final structure now used in classification map:
    - `6.2.1 Cara`
    - `6.2.2 Cuello`
    - `6.2.3 Manos`
    - `6.2.4 Zonas con cicatriz especifica`
    - Third level treatment types:
      - `6.1.1 Antiaging / colageno`
      - `6.1.2 Cicatrices recientes`
      - `6.1.3 Cicatrices antiguas / fibrosis`
      - `6.1.4 Acne / inflamacion cutanea`
      - `6.1.5 Estrias`
- Validation:
  - `dart analyze lib/main.dart` passed with no issues before publish.

## Publish state (2026-02-20)
- Commit pushed to `main`:
  - `cbef9be` - `Reorganize treatment hierarchy with zone-based skin sublevels`
- Workflow results for this commit:
  - `Deploy Web & Android`: `success`
    - Run: `22233579214`
    - URL: `https://github.com/benjamoide/megapanelAI/actions/runs/22233579214`
  - `Flutter CI`: `success`
    - Run: `22233579242`
    - URL: `https://github.com/benjamoide/megapanelAI/actions/runs/22233579242`
  - `pages-build-deployment`: `success`
    - Run: `22233946509`
    - URL: `https://github.com/benjamoide/megapanelAI/actions/runs/22233946509`
- Outcome:
  - GitHub Pages published correctly.
  - Updated APK artifact generated (`mega-panel-app-release`) in deploy run.

## Exact resume point
1. Hardware validation for hierarchical selector UX:
   - select level 1 -> level 2 -> level 3 and confirm final treatment selection maps correctly.
2. Confirm start behavior on locked/screen-off device remains stable after hierarchy changes.
3. If stable, tag/release build and archive tested APK externally if needed.

## Continuation update (2026-02-21 - start flow rollback + APK deploy)
- Reported issue:
  - Treatments/manual showed applied settings but did not actually start until touching the screen again.
- Fix applied (rollback to known-good start behavior from commit `74ae7f5`):
  - `lib/main.dart`
    - `iniciarCiclo`: restored direct start sequence after params:
      - `setPower(true)` -> short delay -> `quickStart(mode: 0)`.
    - `iniciarCicloManual`: restored original start behavior:
      - `0x21` => `quickStart(mode)`
      - `0x20` => `setPower(true)`
    - Removed extra helper `_sendStartHandshake(...)` introduced later.
  - `lib/views/bluetooth_custom_view.dart`
    - `_runManualTreatment`: removed extra 320ms wait after stop.
    - `_runManualTreatment`: call to `iniciarCicloManual(...)` returned to non-awaited behavior (as in `74ae7f5`).
- Git state:
  - Branch: `main`
  - `HEAD`: `a7bc002`
  - Commit: `a7bc002` - `Restore treatment start flow to 74ae7f5 behavior`
- Deploy/APK workflows:
  - `Deploy Web & Android` (manual): `success`
    - Run: `22262040132`
    - URL: `https://github.com/benjamoide/megapanelAI/actions/runs/22262040132`
  - `Deploy Web & Android` (push-triggered): `success`
    - Run: `22262038173`
    - URL: `https://github.com/benjamoide/megapanelAI/actions/runs/22262038173`

## Exact resume point
1. Validate on physical device that RUN starts immediately without extra touch in:
   - Manual flow (from control manual),
   - Daily/weekly/clinic treatment launch flow.
2. Confirm STOP/RUN resume behavior still works after rollback.
3. If confirmed, keep this start sequence as baseline and continue UI refinements.
