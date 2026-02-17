# Mobile Gamepad Server - Complete Setup & Build Guide

This guide gives you:

1. **One-command setup scripts** for GitHub Codespaces.
2. **Build scripts** for Android APK and Windows companion artifacts.
3. **Windows setup script** for running the companion app locally.
4. **Manual steps** you still need to do.

---

## 1) Quick start (GitHub Codespaces)

From repo root:

```bash
chmod +x scripts/*.sh
./scripts/setup-codespace.sh all
source ~/.bashrc
./scripts/build-android-apk.sh
./scripts/build-windows-companion.sh
```

Outputs:

- Android debug APK: `android-app/app/build/outputs/apk/debug/app-debug.apk`
- Windows companion publish folder: `pc-companion/dist/win-x64`

You can also run all steps together:

```bash
./scripts/bootstrap-and-build.sh
```

---

## 2) What each script does

## `scripts/setup-codespace.sh`

Usage:

```bash
./scripts/setup-codespace.sh [all|android|dotnet]
```

- Installs required Linux packages (`openjdk-17-jdk`, curl/unzip/etc.)
- Installs .NET 8 SDK (for companion build)
- Installs Android SDK commandline tools
- Accepts Android SDK licenses
- Installs Android SDK packages:
  - `platform-tools`
  - `platforms;android-34`
  - `build-tools;34.0.0`
- Persists `ANDROID_SDK_ROOT` and PATH in `~/.bashrc`

## `scripts/build-android-apk.sh`

- Runs Gradle debug APK build (uses wrapper when available; otherwise uses installed Gradle 8.14.3)
- Verifies output APK path exists

## `scripts/build-windows-companion.sh`

- Restores .NET dependencies
- Publishes Windows companion as `win-x64` Release build
- Uses `EnableWindowsTargeting=true` to build on Linux/Codespaces

## `scripts/bootstrap-and-build.sh`

- Runs setup + both build scripts in sequence

## `scripts/setup-windows-companion.ps1`

Usage in PowerShell on Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows-companion.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\setup-windows-companion.ps1 -InstallVigem
```

- Installs .NET 8 SDK via winget
- Optionally installs ViGEmBus via winget

---

## 3) Manual steps you must still do

## A) Android device requirements (manual)

- Enable **Developer options** (if installing directly via adb later).
- Allow install of debug APK (or use adb install).
- Grant **camera permission** for QR scanning in-app.

## B) Windows companion runtime prerequisites (manual check)

- Ensure **ViGEmBus** is installed and active in Device Manager.
- Ensure Windows Firewall allows UDP on ports:
  - Discovery: `9877`
  - Streaming: `9876`
- Ensure phone and PC are on same Wi-Fi / hotspot subnet.

## C) Pairing/config steps (manual)

1. Start companion app on Windows.
2. Confirm pairing code and (optional) shared secret in the companion GUI.
3. Open Android app and scan QR from companion.
4. Start streaming and verify status/latency tab on PC.

---

## 4) Build commands reference

## Android APK

```bash
cd android-app
# Wrapper if present
./gradlew --no-daemon clean assembleDebug
# or fallback
gradle --no-daemon clean assembleDebug
```

## Windows companion publish from Codespaces

```bash
cd pc-companion/CompanionApp
dotnet restore
dotnet publish -c Release -r win-x64 --self-contained false -p:EnableWindowsTargeting=true -o ../dist/win-x64
```

---


## Binary-file PR note

- This repository intentionally avoids committing `android-app/gradle/wrapper/gradle-wrapper.jar` to prevent PR UI flows that reject binary diffs with messages like `Binary Files are Not Supported`.
- `scripts/setup-codespace.sh` installs Gradle `8.14.3` so APK builds do not depend on the wrapper JAR being committed.

---

## 5) Common issues


## `apt-get update` fails with Yarn GPG key error

- The setup script now auto-detects this exact error (`NO_PUBKEY 62D54FD4003F6525`) and disables the broken Yarn apt source before retrying.
- If needed, you can manually disable it with:

```bash
sudo sed -i "s|^deb |# deb |g" /etc/apt/sources.list.d/yarn.list
sudo apt-get update
```

## Gradle fails to download dependencies

- Re-run setup and verify outbound access from Codespaces.
- Check proxy/network restrictions in your Codespace org settings.


## Android build fails with plugin not found / HTTP 403

- If you see plugin resolution errors like `com.android.application ... was not found` with references to `Google` repository, your environment cannot reach `https://dl.google.com/dl/android/maven2/`.
- The build script now checks this endpoint first and exits with a clear message when blocked.
- Fix by allowing `dl.google.com` in your proxy/firewall (or run in a network without this restriction), then re-run `./scripts/build-android-apk.sh`.

## Android build fails with `25.0.1`

- This means Gradle/Kotlin picked Java 25 instead of Java 17.
- `scripts/build-android-apk.sh` forces Gradle to Java 17 (`JAVA_HOME` + `ORG_GRADLE_JAVA_HOME` + `-Dorg.gradle.java.home`) and prints the selected Java version.
- The script also uses an isolated `GRADLE_USER_HOME` and stops existing daemons to avoid stale Java 25 daemon reuse.
- It also clears JVM override env vars (`JAVA_TOOL_OPTIONS`, `JDK_JAVA_OPTIONS`, `_JAVA_OPTIONS`) that can force the wrong JDK during Gradle startup.

## QR scan fails on Android

- Confirm camera permission is granted.
- Ensure QR contains `type: mg_pairing_qr` data from companion app.

## Companion receives nothing

- Verify same local network.
- Check firewall UDP ports 9876/9877.
- Verify pairing code matches Android and companion.

---

## 6) Recommended workflow for you

1. In Codespaces: run setup/build scripts.
2. Download `app-debug.apk` and `pc-companion/dist/win-x64` artifacts.
3. On Windows PC: run `setup-windows-companion.ps1 -InstallVigem` once.
4. Launch companion app, then install and launch Android app.
5. Pair via QR and test controller in a gamepad tester/game.
