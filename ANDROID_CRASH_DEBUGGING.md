# Android force-close debugging guide

Recorded on **24 October 2026 (Asia/Karachi)** for `A:\Flutter\pdf_viewer`.

This guide first records the investigation and fix for this application's startup crash, then gives a repeatable command sequence for future crashes. Commands use **Windows PowerShell**. Steps labelled **additional** are reference commands; they were not all executed during the original investigation.

## 1. Identify which stage failed

The supplied launch log contained:

```text
Built build\app\outputs\flutter-apk\app-debug.apk
FATAL EXCEPTION: main
Process: com.example.pdf_viewer
Unable to instantiate activity ... com.example.pdf_viewer.MainActivity
Caused by: java.lang.ClassNotFoundException:
Didn't find class "com.example.pdf_viewer.MainActivity"
```

The APK built, but Android could not instantiate its launcher activity. This was a **native Android startup crash**, before Flutter could display its interface. Build success alone did not prove that the app could launch.

Read the exception chain and identify the specific failure. Here, `Unable to instantiate activity` described the failed operation; `ClassNotFoundException` identified the missing class. For other crashes, follow each `Caused by:` entry and look for the first relevant application frame.

Logs from another PID or another application do not establish what happened in this app. The supplied log also contained background Flutter messages from a different process; those were not the startup failure.

## 2. Inspect the workspace before changing anything

Commands used included:

```powershell
Set-Location 'A:\Flutter\pdf_viewer'
git status --short
rg --files -g AGENTS.md -g '*.dart' -g '*.gradle.kts' -g AndroidManifest.xml -g MainActivity.kt
Get-Content android/app/src/main/kotlin/com/example/pdf_viewer/MainActivity.kt
Get-Content android/app/build.gradle.kts
Get-Content android/app/src/main/AndroidManifest.xml
Get-Content android/settings.gradle.kts
Get-Content android/gradle.properties
Get-Content android/local.properties
Get-Content lib/main.dart
Get-Content test/widget_test.dart
Get-Content pubspec.yaml
```

`git status` identified pre-existing changes, including deleted Dart files and an untracked `z.txt`. These were left alone. Repository instruction files were checked before editing. The open `A:\Flutter\aifile\PROJECT_FLOW.md` was read for background, but it describes another project; this project's actual source determined the fix.

For future investigations, save the original crash log before rebuilding or clearing logs. Do not share configuration files or logs containing credentials without removing those values.

## 3. Compare the three Android names

The investigation found:

| Location | Original value | Meaning |
| --- | --- | --- |
| `android/app/build.gradle.kts` | `namespace = "com.example.pdf_viewer"` | Namespace used to resolve the relative activity name |
| `android/app/src/main/AndroidManifest.xml` | `android:name=".MainActivity"` | Android's registered launcher activity |
| `MainActivity.kt` | `package com.example.aifile` | Package of the compiled Kotlin class |

The manifest therefore requested `com.example.pdf_viewer.MainActivity`, while Kotlin produced `com.example.aifile.MainActivity`.

The source file was already inside `kotlin/com/example/pdf_viewer/`. Its directory did not override its Kotlin `package` declaration.

Android documents that a relative activity name beginning with a period is expanded using the Gradle namespace. The resulting name must identify the actual activity class. [Android activity documentation](https://developer.android.com/guide/topics/manifest/activity-element#nm)

An additional search you can use next time:

```powershell
rg -n 'package |namespace|applicationId|MainActivity' android/app
```

`applicationId` identifies the installed application. It is a separate setting from the namespace, even though both are `com.example.pdf_viewer` here. Do not rename the application's identity merely to repair an activity declaration.

## 4. Fix the class name that caused the crash

Changed the first line of `android/app/src/main/kotlin/com/example/pdf_viewer/MainActivity.kt`:

```diff
-package com.example.aifile
+package com.example.pdf_viewer
```

After this edit, the class's fully qualified name matched the manifest's resolved activity name. The Gradle namespace, application ID, and manifest activity declaration did not need changes.

This Kotlin change required a new APK and installation. Flutter hot reload cannot replace an Android activity class.

## 5. Fix the separate PDF navigation problem found during inspection

`lib/main.dart` owned a navigator key and used it for incoming PDFs and error dialogs, but the key was not attached to `MaterialApp`.

Added:

```dart
return MaterialApp(
  navigatorKey: _navigatorKey,
  // Existing application settings follow.
);
```

Without that connection, `_navigatorKey.currentState` and `currentContext` could be null, so the null-aware calls would silently skip navigation or dialogs. This was a separate functional bug; the package mismatch caused the reported force close.

The channel name stayed `aifile/pdf` on both sides. A method-channel identifier is a shared string contract; it does not have to match the Android package name.

## 6. Locate the tools and connected device

Commands used:

```powershell
Get-Command flutter,dart,adb -ErrorAction SilentlyContinue |
  Select-Object Name,Source
adb devices -l
```

The connected device was:

```text
0a39ba727d73    device    model:23053RN02A
```

Use the serial from your current `adb devices -l` output when it differs. `-s` selects a particular device and avoids ambiguity when several are connected. [ADB documentation](https://developer.android.com/tools/adb)

An initial `flutter --version` attempt stalled inside the restricted execution environment. Inspection of Flutter's Windows startup script showed that startup acquires a lock in the SDK cache outside the workspace. Builds and Flutter checks were subsequently run with the required access to SDK and Gradle caches. This tooling restriction was separate from the application crash; no lock files were deleted.

Additional environment checks for future use:

```powershell
flutter --version
flutter doctor -v
flutter devices
```

## 7. Run analysis and meaningful regression tests

Commands used:

```powershell
flutter analyze --no-pub
flutter test --no-pub
git diff --check
```

Results:

```text
No issues found!
All tests passed!  (3 tests)
```

The generated counter test did not describe this PDF application. It was replaced with three widget tests in `test/widget_test.dart`:

1. Normal launch shows the PDF upload button.
2. A `PDF_ERROR` during initial loading displays an error dialog that can be dismissed.
3. A native `pdfError` message delivered to the running app displays the error dialog.

The tests mock the Android method channel. The two error tests exercise the navigator connection. They do **not** prove that Android can load `MainActivity`, and they do not render a real PDF; those checks require the APK and device steps below.

`--no-pub` reused the dependencies already resolved in this workspace. On a fresh checkout or after changing dependencies, run `flutter pub get` first. [Flutter CLI documentation](https://docs.flutter.dev/reference/flutter-cli)

## 8. Build a fresh APK for the phone

The first build command was:

```powershell
flutter build apk --debug --no-pub
```

That build targeted several CPU architectures and was delayed while Gradle waited on dependency downloads. Diagnostics included checking Gradle daemon logs and a Java thread dump. The broad build was interrupted, then restarted for the connected phone's ARM64 architecture:

```powershell
flutter build apk --debug --no-pub --target-platform android-arm64
```

Result:

```text
Built build\app\outputs\flutter-apk\app-debug.apk
```

The successful ARM64 build took about 89 seconds. This architecture choice shortened verification; it was not the crash fix. For another device, check its ABI rather than assuming ARM64:

```powershell
# Additional check for future use.
adb -s 0a39ba727d73 shell getprop ro.product.cpu.abi
```

## 9. Inspect the actual APK contents

The APK was inspected with Android SDK `apkanalyzer`:

```powershell
& 'C:\Users\abdul\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\apkanalyzer.bat' dex packages --defined-only build/app/outputs/flutter-apk/app-debug.apk |
  Select-String 'MainActivity'
```

The old APK contained `com.example.aifile.MainActivity`. The rebuilt APK contained `com.example.pdf_viewer.MainActivity`. This confirmed the correction reached the packaged bytecode, rather than only changing source text.

Check the file timestamp if you suspect you are inspecting an old APK:

```powershell
Get-Item build/app/outputs/flutter-apk/app-debug.apk |
  Format-List Length,LastWriteTime
```

Additional command to inspect the merged manifest inside the APK:

```powershell
& 'C:\Users\abdul\AppData\Local\Android\Sdk\cmdline-tools\latest\bin\apkanalyzer.bat' manifest print build/app/outputs/flutter-apk/app-debug.apk
```

Replace the SDK path if needed. `apkanalyzer` comes with Android SDK Command-Line Tools. [APK Analyzer documentation](https://developer.android.com/tools/apkanalyzer)

## 10. Install and test normal startup

Commands used:

```powershell
adb -s 0a39ba727d73 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s 0a39ba727d73 shell am force-stop com.example.pdf_viewer
adb -s 0a39ba727d73 shell am start -W -n com.example.pdf_viewer/.MainActivity
adb -s 0a39ba727d73 shell pidof com.example.pdf_viewer
```

Observed results:

```text
Performing Streamed Install
Success
Status: ok
LaunchState: COLD
Activity: com.example.pdf_viewer/.MainActivity
11533
```

`install -r` updates the installed app while retaining its data. `force-stop` stops it so the next launch creates a new process. `am start -W` starts the activity and waits for a launch result. `pidof` returned the running application's process ID.

`Status: ok` and a PID are useful evidence, but the app could crash afterward. Check logs and exercise the actual interface as well. [ADB activity-manager documentation](https://developer.android.com/tools/adb#am)

## 11. Test a PDF while the app is already running

A small, valid one-page test PDF containing `PDF launch verification` was created as `build/crash-verification.pdf`. The commands below assume that fixture exists. For future use, substitute a known-good PDF from your machine.

```powershell
adb -s 0a39ba727d73 push build/crash-verification.pdf /data/local/tmp/pdf-viewer-crash-verification.pdf
adb -s 0a39ba727d73 shell run-as com.example.pdf_viewer cp /data/local/tmp/pdf-viewer-crash-verification.pdf cache/crash-verification.pdf
adb -s 0a39ba727d73 shell am start -W -a android.intent.action.VIEW -t application/pdf -d file:///data/user/0/com.example.pdf_viewer/cache/crash-verification.pdf -n com.example.pdf_viewer/.MainActivity
```

Android reported that it delivered the intent to the existing activity. That message is expected for the configured `singleTop` activity. The app stayed running.

This exercises `onNewIntent` -> `pdfPath` -> `openPdf` channel message -> Flutter navigation. `run-as` requires a debuggable app; these fixture-copy commands are intended for this debug build.

## 12. Test a PDF from a stopped app

Commands used:

```powershell
adb -s 0a39ba727d73 shell am force-stop com.example.pdf_viewer
adb -s 0a39ba727d73 shell am start -W -a android.intent.action.VIEW -t application/pdf -d file:///data/user/0/com.example.pdf_viewer/cache/crash-verification.pdf -n com.example.pdf_viewer/.MainActivity
adb -s 0a39ba727d73 shell pidof com.example.pdf_viewer
```

Observed: `Status: ok`, `LaunchState: COLD`, and a new PID (`12355`). Logs confirmed `PdfDocument initial load` for the fixture, and a screenshot visibly showed the rendered page.

This exercises activity creation -> `getInitialPdf` -> native path extraction -> Flutter navigation -> PDF rendering. The running-app intent was also delivered again after the cold-start check.

These device checks used an explicit `VIEW` intent with a `file://` URI. They did not verify another app's `content://` permission grants, the Android chooser, `ACTION_SEND`, the upload picker, or release mode. Test those separately when changing those paths.

## 13. Check logs and capture visual evidence

Commands used included:

```powershell
# The PID is an example from this investigation; replace it after every restart.
adb -s 0a39ba727d73 logcat -d -t 300 --pid=12355 -s AndroidRuntime flutter
adb -s 0a39ba727d73 shell screencap -p /data/local/tmp/pdf-viewer-verification.png
adb -s 0a39ba727d73 pull /data/local/tmp/pdf-viewer-verification.png build/pdf-viewer-verification.png
```

The logs showed successful PDF loading without the reported activity exception. The screenshot was opened and inspected after loading completed; an earlier screenshot taken during loading showed only the viewer background.

The PDFium WASM debug warning was informational and did not cause this crash. Follow the fatal exception and the behavior being reproduced before treating every warning as the root cause.

## 14. Reusable sequence for the next force close

The following is an **additional workflow**, assembled for future debugging. Run commands in order and use a second PowerShell terminal for live capture.

### 14.1 Record the environment and preserve existing evidence

```powershell
Set-Location 'A:\Flutter\pdf_viewer'
git status --short
flutter --version
flutter doctor -v
adb devices -l
New-Item -ItemType Directory -Force -Path build/crash-debug
adb -s 0a39ba727d73 logcat -b all -d -v threadtime > build/crash-debug/before-reproduction.txt
```

Use a different output filename for each investigation if you need to keep previous captures. Files under `build/` are temporary and are deleted by `flutter clean`; copy evidence elsewhere before cleaning.

### 14.2 Start a live capture in terminal A

```powershell
adb -s 0a39ba727d73 logcat -b all -v threadtime > build/crash-debug/reproduction.txt
```

Keep this running while reproducing the issue. Press **Ctrl+C** afterward to stop capture. Capturing all buffers avoids losing native crash messages or filtering out an app that exits before you can obtain its PID. [Logcat documentation](https://developer.android.com/tools/logcat)

### 14.3 Reproduce the exact failing action in terminal B

For a startup failure:

```powershell
adb -s 0a39ba727d73 shell am force-stop com.example.pdf_viewer
adb -s 0a39ba727d73 shell am start -W -n com.example.pdf_viewer/.MainActivity
```

For a crash after opening a file, first launch the app, then open the same file through the same picker, VIEW, or Share flow that failed. Record the filename, URI type, action, and whether the app was already running.

To collect Flutter's own launch diagnostics as well:

```powershell
flutter run -d 0a39ba727d73 -v 2>&1 |
  Tee-Object -FilePath build/crash-debug/flutter-run.txt
```

### 14.4 Stop capture and find the relevant failure

```powershell
Select-String -Path build/crash-debug/reproduction.txt -Pattern 'FATAL EXCEPTION|Caused by:|ClassNotFoundException|SecurityException|Fatal signal|ANR in|Unhandled Exception|com.example.pdf_viewer' -Context 5,15
adb -s 0a39ba727d73 logcat -b crash -d -v threadtime
```

Match the application package, process ID, and reproduction time. Read the surrounding stack trace, not only the matched line. A crash buffer can contain older failures. A log search with no matches is not proof of correctness; also inspect visible behavior and process survival.

If the app stays alive, get its current PID and use it to narrow follow-up logs:

```powershell
adb -s 0a39ba727d73 shell pidof com.example.pdf_viewer
# Replace 12355 with the PID returned above.
adb -s 0a39ba727d73 logcat -d --pid=12355 -v threadtime
```

Do not assign the result to `$PID`: PowerShell reserves that variable for its own process. Remember that an app's PID changes after restart.

### 14.5 Choose the next inspection from the evidence

| Evidence | Next inspection |
| --- | --- |
| `Unable to instantiate activity` and `ClassNotFoundException` | Compare manifest activity, namespace, Kotlin package, and APK contents, as in this incident |
| Dart `Unhandled Exception` or Flutter stack trace | Inspect the first relevant Dart frame and the inputs that reached it |
| `SecurityException` | Inspect the denied operation, manifest/runtime permissions, and URI grants |
| `FileNotFoundException` while opening a PDF | Check the URI, stream access, file existence, and whether permission is still valid |
| `Fatal signal` or native crash backtrace | Inspect the native crash log, library, ABI, and symbols associated with the installed build |
| `ANR in` or an app that freezes | Investigate work blocking the main thread; capture an `adb bugreport` if needed |
| Gradle fails and no APK is built | Investigate the build error and dependencies before debugging app launch |

These are starting points, not diagnoses. Apply the package fix only when the evidence shows the same mismatch.

### 14.6 Make one focused fix, rebuild, and repeat the same reproduction

```powershell
flutter analyze
flutter test
flutter build apk --debug --target-platform android-arm64
adb -s 0a39ba727d73 install -r build/app/outputs/flutter-apk/app-debug.apk
adb -s 0a39ba727d73 shell am force-stop com.example.pdf_viewer
adb -s 0a39ba727d73 shell am start -W -n com.example.pdf_viewer/.MainActivity
git diff --check
git diff --stat
```

Use the target architecture appropriate to your device. Reproduce the original action after reinstalling and inspect fresh logs. Add a regression test that would fail without the fix whenever practical. Native startup still needs device verification even when widget tests pass.

Use `flutter clean` only when evidence suggests stale generated outputs. If needed, preserve logs first, then run:

```powershell
flutter clean
flutter pub get
flutter build apk --debug --target-platform android-arm64
```

Cleaning cannot correct an incorrect package declaration. It also discards generated outputs, including any evidence saved in `build/`.

## 15. Optional commands for a stalled build

During this incident, Gradle daemon logs, process information, and Java thread dumps were inspected. For future use, begin with verbose output:

```powershell
flutter build apk --debug --target-platform android-arm64 -v
Get-Process dart,java -ErrorAction SilentlyContinue |
  Format-Table Id,CPU,WorkingSet,StartTime
Get-ChildItem "$env:USERPROFILE\.gradle\daemon" -Recurse -Filter 'daemon-*.out.log' |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 3 FullName,LastWriteTime
```

Read the latest applicable daemon log with `Get-Content -LiteralPath '<full log path>' -Tail 80`.

An advanced diagnostic used during this investigation was:

```powershell
# Historical Gradle PID; obtain the active Gradle daemon PID before reuse.
& 'C:\Program Files\Android\Android Studio\jbr\bin\jcmd.exe' 13488 Thread.print
```

A thread dump helped distinguish network waiting from compilation. Access to another process may require permissions. Do not terminate unrelated Java/Dart processes or delete cache locks merely because a build is slow. Stop your own foreground build with Ctrl+C before retrying.

## 16. Completion record for this incident

| Check | Result |
| --- | --- |
| Kotlin package matches registered activity | Corrected to `com.example.pdf_viewer` |
| Navigator attached to `MaterialApp` | Corrected |
| Flutter analysis | Passed; no issues |
| Widget tests | All 3 passed |
| ARM64 debug APK | Built successfully |
| APK class inspection | Correct activity class present |
| Installation on model 23053RN02A | Successful |
| Normal cold launch | Successful; app remained running |
| Explicit file VIEW while running | Delivered to existing activity; app remained running |
| Explicit file VIEW from stopped state | Successful; PDF load confirmed in logs and screenshot |
| Patch whitespace check | Passed |

When recording the next incident, include the triggering action, original exception, root cause, changed files, commands, observed results, and any paths left untested.
