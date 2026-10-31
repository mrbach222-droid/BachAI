# Bách AI Native 0.1

SwiftUI + Gemini API + Apple Speech (vi-VN) + AVSpeechSynthesizer.

## Build in GitHub Actions
Open **Actions > Build Bach AI iOS > Run workflow**. The workflow generates the Xcode project using XcodeGen and compiles for iOS Simulator with signing disabled. Inspect the build log artifact if it fails.

**This is NOT an installable IPA.** Installation on a physical iPhone requires valid code signing and a distribution route.

## Gemini
Create a key in Google AI Studio and enter it in the app's Settings screen. The key is saved to Keychain, never GitHub. Check current Free Tier availability and privacy terms before sending personal information. For distributing an app, use a backend to protect the key.

## Scope
Current: chat, push-to-talk Vietnamese transcription, spoken replies. Next: App Intents/Siri, reminders/calendar, signing and device distribution.

## Device IPA
The main-branch workflow packages an unsigned iOS device IPA for signing locally with ZSign. Never upload certificates or private keys to this repository.
