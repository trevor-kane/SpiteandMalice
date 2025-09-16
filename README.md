# Spite and Malice for macOS

A modern SwiftUI implementation of the classic card game Spite and Malice (also known as Skip-Bo). The project is structured as a Swift Package with a reusable core engine and a SwiftUI executable target that offers a polished macOS experience.

## Features

- 🎴 Fully modelled card engine that captures the traditional Spite and Malice rules including stock piles, discard piles, build piles and wild kings.
- 👥 Local human vs. AI rival play with a personality-driven opponent and adaptive pacing.
- 🧠 Smart turn validation, contextual hints and a dynamic activity log to help new players learn the game quickly.
- 🎨 Responsive SwiftUI interface designed specifically for macOS with keyboard shortcuts, animations, accessibility support and a dark-mode friendly palette.
- ♻️ Automatic recycling of build piles into the draw pile and game state persistence between launches.

## Project layout

```
SpiteandMalice
├── Package.swift
├── README.md
├── Sources
│   ├── SpiteAndMaliceCore       # Pure game logic and models
│   └── SpiteAndMaliceApp        # SwiftUI application layer and resources
└── Tests
    └── SpiteAndMaliceCoreTests  # Engine unit tests
```

The separation makes it easy to reuse the engine in other front-ends (for example an iOS or visionOS build) while keeping the user interface lightweight.

## Getting started

1. Open `Package.swift` in Xcode 15 or newer. Xcode will generate a macOS app scheme named **SpiteAndMaliceApp**.
2. Select the **My Mac** destination and run the project (`⌘R`).
3. To run tests, choose the **SpiteAndMaliceCoreTests** scheme or run `swift test` from Terminal.

The executable target builds a fully fledged `.app` bundle when run from Xcode, so you can archive and notarize it like any other macOS application.

## Gameplay overview

- Each player receives a stock pile of 20 face-down cards; the top card is flipped face-up.
- Players draw up to five cards in hand at the start of their turn.
- Build piles in the centre advance from Ace (1) to Queen (12). Kings act as wild cards and adopt the needed value when played.
- You can play from your hand, your stock pile or any of your four discard piles.
- End your turn by discarding a card from your hand onto one of your discard piles.
- The first player to empty their stock pile wins.

The UI supports drag-select-to-target interactions, keyboard shortcuts, rule reminders and a collapsible help panel.

## Assets

The SwiftUI layer uses SF Symbols and programmatic drawing, so no raster assets are required. Custom colors and typography styles are defined in code to ensure the experience adapts seamlessly to light and dark appearances.

## Minimum requirements

- macOS 13 Ventura or later
- Xcode 15 or later (for building)

## Roadmap

- Online multiplayer powered by Game Center
- Richer AI personalities and configurable difficulty levels
- Enhanced animation and sound design
- Comprehensive tutorial and achievements

Contributions and feedback are welcome!
