# Phone app

Recording needs the local Omi variant installed separately.
`start.command` prepares the Mac services but does not install the phone
app. After installing, pair it via the [pairing guide](NGROK.md).
An Android build is being prepared; the steps below cover iPhone.

## Preparing the Mac

You need an Apple Silicon Mac, Xcode, Flutter, CocoaPods, and your own
Apple Account. There is no tie to an iPhone model or M-processor
generation. The project sets iOS 15.0 as the minimum; Xcode must support
the phone's iOS version and run on your macOS.

1. Install Xcode from the App Store, open it, accept the license, and
   wait for the iOS components. Under **Settings → Locations → Command
   Line Tools**, pick the installed Xcode.
2. Install [Flutter for iOS](https://docs.flutter.dev/platform-integration/ios/setup)
   and add it to PATH per the instructions. Version 3.44.5 or newer.
3. After Homebrew is prepared by `start.command`, install
   [CocoaPods](https://formulae.brew.sh/formula/cocoapods):
   `brew install cocoapods`. Check `flutter doctor -v`: the Xcode section
   must be error-free; Android is not needed for this install.

## Signing and the phone

The free **Personal Team** is enough to install on your own iPhone.
Its profile lasts 7 days: after that the app must be re-signed and
reinstalled. This is an
[Apple restriction](https://developer.apple.com/help/account/basics/about-your-developer-account).

1. In Xcode open **Settings → Accounts**, add your Apple Account, and
   select the Personal Team.
2. Open **Manage Certificates → + → Apple Development**. Xcode creates
   the certificate and the private key on this Mac; no manual CSR is
   needed. If a certificate with a working private key already exists,
   do not create another.
   [Apple's guide](https://developer.apple.com/documentation/Xcode/sharing-your-teams-signing-certificates).
3. In Keychain Access open **My Certificates → Apple Development**.
   The private key must sit under the certificate. The Team ID is the
   10 characters in **Subject Name → Organizational Unit (OU)** in the
   certificate properties. The number in parentheses in the name can
   differ — [Apple explains the difference](https://developer.apple.com/forums/thread/811970).
4. Connect the unlocked iPhone with a data USB cable and confirm trust
   for the Mac. In Xcode open **Window → Devices and Simulators** and
   wait for the phone. On the iPhone enable **Settings → Privacy &
   Security → Developer Mode**, reboot it, and confirm.

## Install

[Fetch the project and prepare the Mac services](START.md#install).
From the project folder:

```bash
cd app
bash setup.sh ios personal
```

The script checks Xcode with the iOS SDK, Flutter, CocoaPods, the
certificate with its private key, and phone availability. The Team ID is
entered hidden on request. If something is missing, a hint appears: fix
the cause and press Enter to recheck; `q` quits. The install starts only
after all checks pass.

To check without building or installing: `./start.command --iphone-check`
from the project root. That mode also lets you fix problems and recheck.
Apple Account access for profile issuance is finally verified by Xcode at
signing time; a certificate alone does not guarantee the account login is
still valid.

After the checks the script prepares dependencies, builds, installs, and
launches the app. If macOS asks for access to the signing key, allow it
with your Mac password. On an "untrusted developer" message, open
**Settings → General → VPN & Device Management** on the iPhone and trust
your developer profile.

The phone is picked from connected devices. With several, the script
offers a choice; `OMI_IOS_DEVICE_ID` skips the dialog. If Xcode reports
the identifier as taken, set your own `OMI_PERSONAL_BUNDLE_ID`. The
address and the key are entered in the app after installation.
Old `.local`, `.venv`, `build`, keys, and signing settings need no
migration.

Physically verified: iPhone 17 Pro with iOS 26.6, Xcode 26.6,
Flutter 3.44.5, CocoaPods 1.16.2. A full repeat install on a clean Mac is
not yet verified.

[Reinstall and build verification](DEVELOPMENT.md#iphone-build) ·
[Running and CV1 recording](START.md)
