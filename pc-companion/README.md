# PC Companion (Windows)

This companion app listens for UDP gamepad packets from the Android app, replies to discovery broadcasts, and emulates a virtual Xbox 360 controller using ViGEm. The Windows UI provides pairing, QR-based key exchange, mapping/profile configuration, and live connection/latency telemetry.

## Requirements

- Windows 10/11
- [ViGEmBus driver](https://github.com/ViGEm/ViGEmBus) installed
- .NET 8 SDK

## Quick setup scripts

From repo root on Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows-companion.ps1 -InstallVigem
```

From GitHub Codespaces/Linux for build artifacts:

```bash
./scripts/setup-codespace.sh dotnet
./scripts/build-windows-companion.sh
```

## Build & run

```bash
cd pc-companion/CompanionApp
dotnet restore
dotnet run -- --stream-port 9876 --discovery-port 9877
```

On first launch the app creates `companion-settings.json` in the current working directory. Use the GUI to update pairing code, shared secret, and mapping profiles, then scan the QR code in the Android app.

## Behavior

- Discovery responder listens on UDP port `9877` and replies with a JSON payload containing stream port + pairing metadata.
- UDP listener receives JSON packets on `9876` and maps them to a virtual Xbox 360 controller.
- Windows UI lets you pick/edit mapping profiles and toggle Windows autostart.
- QR pairing bootstraps ECDH key exchange to derive a session key for AES-GCM encryption.
- Status tab shows connection state and rolling latency chart.

## Notes

- The Android app expects standardized axis/button names (`left_stick_x`, `a`, `lb`, etc.).
- If shared secret is configured, Android can still send encrypted packets (`gamepad_encrypted`), but QR pairing is preferred.
- For full environment + manual steps, see `docs/SETUP_AND_BUILD_GUIDE.md`.
