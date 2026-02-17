# Mobile Gamepad Server

This repository contains a native Android application that streams physical gamepad input from a phone to a PC companion app over the local Wi‑Fi or mobile hotspot network.

## Project layout

- `android-app/`: Native Android application for capturing gamepad input and sending it over UDP.
- `pc-companion/`: Windows companion app that listens for UDP packets, shows a pairing/mapping GUI, and emulates a virtual controller.
- `scripts/`: Preconfigured setup/build scripts for Codespaces and Windows.
- `docs/SETUP_AND_BUILD_GUIDE.md`: Complete setup + build guide.

## Automated setup and build (Codespaces)

```bash
chmod +x scripts/*.sh
./scripts/setup-codespace.sh all
source ~/.bashrc
./scripts/build-android-apk.sh
./scripts/build-windows-companion.sh
```

One-command variant:

```bash
./scripts/bootstrap-and-build.sh
```

> Note: To avoid PR creation issues in some UIs (`Binary Files are Not Supported`), the Gradle wrapper JAR is not committed; setup installs Gradle for build fallback.

## Android app overview

The Android app sends JSON payloads over UDP whenever a connected gamepad reports axis or button events. You can configure the PC IP address and port on the main screen, or use the discovery button to fill it automatically.

### Example payload

```json
{
  "type": "gamepad",
  "timestamp": 1713912345678,
  "axes": {
    "x": 0.2,
    "y": -0.1
  },
  "buttons": {
    "button_a": true
  },
  "deviceName": "Xbox Wireless Controller"
}
```

### Build instructions

1. Open `android-app/` in Android Studio.
2. Connect a controller via Bluetooth or USB to your phone.
3. Use **Scan QR pairing code** to pull host/port + pairing metadata from the PC companion, or enter the host/port manually.
4. If using manual discovery, enter the pairing code (and optional shared secret) from `pc-companion/CompanionApp/companion-settings.json`.
5. Tap **Discover PC** to auto-fill the host/port or enter them manually.
6. Tap **Start streaming** to begin foreground streaming.

The PC companion app consumes these packets and emulates a virtual Xbox 360 controller via ViGEm. It also exposes a QR code that bootstraps a stronger ECDH-based key exchange for encrypted packets and includes a status tab with connection/latency information. See `pc-companion/README.md` and `docs/SETUP_AND_BUILD_GUIDE.md` for setup.
