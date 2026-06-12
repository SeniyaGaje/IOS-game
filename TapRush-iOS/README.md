# Tap Rush iOS SwiftUI Version

This folder contains the SwiftUI version of the JavaScript Tap Rush game.

## How to open it in Xcode

1. On a Mac, open Xcode.
2. Choose `File > New > Project`.
3. Select `iOS > App`.
4. Use these settings:
   - Product Name: `TapRush`
   - Interface: `SwiftUI`
   - Language: `Swift`
5. Delete the default `ContentView.swift` and app entry file that Xcode creates.
6. Drag `TapRushApp.swift` and `ContentView.swift` from this folder into the Xcode project navigator.
7. Make sure `Copy items if needed` is checked.
8. Select an iPhone simulator or a connected iPhone, then press Run.

## Features

- Big center tap button
- Score display
- 10-second countdown timer
- Button disables when the timer reaches zero
- Final score game-over screen
- Play Again restart button
- High score saved using `@AppStorage`
- Combo system: taps within 0.5 seconds increase the multiplier
- Trap colour: green gives double combo points, grey subtracts combo points

You need macOS and Xcode to build, run, or deploy this on an iOS device.
