## Prerequisites
- Ensure Flutter SDK is installed and on PATH.
- Ensure Android toolchain (Android Studio, SDK, emulator) is installed and a virtual device is available.

## Commands to Execute
1. Check toolchain:
   - `flutter --version`
   - `flutter doctor -v`
   - `flutter devices`
2. Install dependencies:
   - `flutter pub get`
3. Static analysis and tests:
   - `flutter analyze`
   - `flutter test -r compact`
4. Run the app on Android (preferred target):
   - Start an emulator if none is running (via Android Studio), then:
   - `flutter run -d emulator`
   - If a physical device is connected: `flutter run -d <device_id>`
5. Capture logs and verify features:
   - Login/Register/OTP flows
   - Complaint creation/assignment/verification
   - Notifications appearance (Android 13+ requires user permission)

## Notes
- Windows desktop target may fail because some plugins (e.g., `firebase_messaging`) are mobile-only; prioritize Android.
- iOS requires adding `ios/Runner/GoogleService-Info.plist` before running.

## Output to Provide
- Command outputs for version, doctor, devices, analysis, tests.
- Run logs up to first successful frame.
- Any errors encountered, with file references and fixes.

Once approved, I will execute these commands in your workspace and report the results with logs and any follow-up fixes.