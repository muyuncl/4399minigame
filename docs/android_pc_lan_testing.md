# Android/PC LAN Testing

This copy is for testing Windows and Android cross-play on the same Wi-Fi.

## What Changed

- Project is locked to landscape orientation.
- Touch input emulates mouse input, so existing click and drag UI can work on Android.
- Android export preset `Android APK` is added.
- Android network permissions are enabled in the export preset:
  - `INTERNET`
  - `ACCESS_NETWORK_STATE`
  - `ACCESS_WIFI_STATE`

## Test Flow

1. Connect the PC and Android phone to the same Wi-Fi.
2. Start the game on both devices.
3. Enter `PVP双端联机`.
4. On the host device, click `创建房间`.
5. On the client device, enter the host IPv4 address and port `7777`.
6. Click `加入房间`.
7. After connected, click `进入PVP对战`.

Either PC or Android can be the host. If one direction fails, try PC as host first because Windows firewall prompts are easier to see and approve.

## Android Export Requirements

Godot needs these installed before APK export:

- Godot Android export templates matching the editor version: `4.6.3.stable.mono`
- Android SDK
- Android build tools
- JDK configured in Godot Editor Settings

Current machine check result:

- Missing Android export templates:
  - `android_debug.apk`
  - `android_release.apk`
- Missing/invalid Java SDK path in Godot Editor Settings.
- Missing/invalid Android SDK path in Godot Editor Settings.
- Missing Android SDK `platform-tools`, including `adb`.
- Missing Android SDK `build-tools`, including `apksigner`.

This project is GDScript-only. If you use the Mono editor, Godot may still show a C#/.NET Android export experimental warning because the editor build is Mono. For the cleanest Android export path, use the standard non-Mono Godot editor/export templates unless we later add C# code.

For quick testing, use the debug export:

```powershell
& 'G:\Godot_v4.6.3-stable_mono_win64\Godot_v4.6.3-stable_mono_win64.exe' --headless --path 'C:\Users\NewAdmin\Desktop\MG\4399minigame-android-pc' --export-debug 'Android APK' 'C:\Users\NewAdmin\Desktop\MG\4399minigame-android-pc\builds\android\4399minigame.apk'
```

## Common Connection Problems

- Windows firewall blocks the PC host. Allow the game/Godot on private networks.
- The Wi-Fi router has AP isolation enabled, so devices on the same Wi-Fi cannot see each other.
- Phone is on mobile data instead of Wi-Fi.
- PC and phone are on different subnets, such as guest Wi-Fi vs main Wi-Fi.
- Client entered the wrong IP. Use the host page's displayed IPv4 address, usually `192.168.x.x`.
