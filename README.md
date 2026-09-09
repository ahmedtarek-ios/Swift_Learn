<div align="center">
  <picture>
    <source
      media="(prefers-color-scheme: dark)"
      srcset="./Swift%20Learn/Assets.xcassets/CodeAscensionDark.imageset/CodeAscensionDark.png"
    >
    <source
      media="(prefers-color-scheme: light)"
      srcset="./Swift%20Learn/Assets.xcassets/CodeAscensionLight.imageset/CodeAscensionLight.png"
    >
    <img
      src="./Swift%20Learn/Assets.xcassets/CodeAscensionTransparent.imageset/CodeAscensionTransparent.png"
      alt="Swift Learn Code Ascension logo"
      width="320"
    >
  </picture>

  <h1>Swift Learn</h1>

  <p><strong>Learn Swift by coding, understanding, and progressing—not by memorizing.</strong></p>

  <p>A free, interactive Swift learning journey for iPhone, iPad, Mac, and Apple TV.</p>

  <p><strong>Created by <a href="https://github.com/ahmedtarek-ios">Ahmed Tarek</a></strong></p>
</div>

---

## About Swift Learn

Swift Learn transforms Swift language material into a practical, code-first learning journey. Instead of asking developers to read an entire programming book from beginning to end, the app breaks the language into focused lessons that encourage learners to inspect code, predict results, complete challenges, understand feedback, and build confidence one skill at a time.

The current app contains **486 ordered, source-linked lessons** derived from the project's selected Swift 6.4 beta source snapshot. Each lesson has a clear objective, a Swift code challenge, answer choices, immediate feedback, and a source reference. Completing a lesson saves progress and unlocks the next step in the journey.

Swift Learn is designed for developers who want to:

- start learning Swift with a clear path;
- strengthen weak or forgotten language concepts;
- practice in short, focused sessions;
- understand why code works instead of memorizing answers;
- see meaningful progress and achievements;
- continue learning through an experience built for Apple platforms.

## My Vision

> My vision is to make learning Swift feel like an adventure rather than homework. I want every developer to have a free, clear, and enjoyable way to study: one focused challenge at a time, with immediate feedback, visible progress, and a reason to return. Swift Learn should help learners move beyond reading syntax and turn knowledge into skills they can understand, remember, and use in real projects.

The long-term goal is a complete learning environment where developers can:

- learn every important Swift language concept through practice;
- predict, write, repair, refactor, debug, test, and reuse code;
- separate lesson completion from real mastery;
- revisit skills that need more practice;
- combine knowledge through larger challenges and projects;
- grow from a first Swift lesson toward professional development skills;
- learn without making AI or an internet connection a requirement for core study.

## Learning Should Be Fun

Swift Learn uses progression, interaction, and celebration to make study feel rewarding.

### Learn by doing

Every lesson asks the learner to interact with Swift code. The goal is active practice, not passive reading.

### Receive immediate feedback

After checking an answer, the learner sees whether it is correct and receives an explanation. An incorrect answer does not erase existing progress; it becomes another chance to understand the concept.

### Follow a clear journey

Lessons unlock in order, so the learner always knows what is available, what is complete, and what comes next.

### See progress grow

The app displays completed lessons, completed levels, overall progress, and earned badges. Progress is saved locally with SwiftData.

### Celebrate achievements

Achievement milestones reward the first completed lesson, the first completed level, lesson-count milestones, individual level completion, and completion of the current curriculum source.

### Make the experience personal

Learners can save a display name, choose an avatar, select system/light/dark appearance, and use the system or reduced-motion experience.

## Current Learning Loop

```text
Choose a lesson
      ↓
Read the objective and instruction
      ↓
Inspect the Swift code
      ↓
Choose the missing code
      ↓
Check the answer
      ↓
Understand the feedback
      ↓
Complete the skill and unlock the next lesson
```

## Current Features

- 486 ordered Swift lessons
- versioned and source-linked curriculum data
- short code-completion challenges
- deterministic answer evaluation
- immediate success and retry feedback
- sequential lesson unlocking
- local progress persistence with SwiftData
- learner profiles and avatar choices
- lesson, level, milestone, and source-completion achievements
- achievement unlock celebrations
- system, light, and dark appearances
- system and reduced-motion preferences
- accessibility identifiers and adaptive SwiftUI layouts
- shared project targets for iPhone, iPad, Mac, and Apple TV
- no external package dependencies

## Apple Platform Experience

Swift Learn shares its curriculum, progression rules, and learning logic across Apple platforms while allowing the interface to adapt to each device.

| Platform | Intended experience |
| --- | --- |
| iPhone | Focused lessons, quick practice, progress, and review |
| iPad | More space for lessons, code, keyboard, and touch interaction |
| Mac | A larger learning workspace for deeper study and future projects |
| Apple TV | Focus-based challenges, prediction, ordering, and review |

The current Xcode target supports iOS/iPadOS, macOS, and tvOS. The project is still under active development; full Mac and Apple TV UI-runtime verification remains incomplete.

## Curriculum Accuracy

The curriculum is kept separate from the interface and is linked to a versioned Swift source snapshot. This makes lesson coverage traceable and prevents presentation code from becoming the source of curriculum truth.

Current source state:

- 486 canonical lessons are implemented;
- 649 source headings have recorded coverage decisions;
- repeated concepts reuse canonical lesson identities instead of creating duplicate lessons;
- lesson order and locked-state validation are enforced in the Domain layer;
- editorial and Swift 6.4-specific technical validation are still in progress.

The application currently uses Swift language mode 6.0. The curriculum source version and the compiler language mode are intentionally reported separately.

## Architecture

Swift Learn follows **MVVM + Clean Architecture**:

```text
Presentation → Domain ← Data
                    ↑
             App composition
```

| Layer | Responsibility |
| --- | --- |
| `Presentation` | SwiftUI views, view models, display state, and user intent |
| `Domain` | Entities, repository contracts, progression rules, and use cases |
| `Data` | Bundled curriculum loading and SwiftData persistence |
| `App` | Dependency construction and injection |

Views render state and forward actions. View models call Domain use cases. Domain code owns the learning rules without importing SwiftUI or SwiftData. Data implementations satisfy repository contracts declared by Domain.

## Technology

- Swift
- SwiftUI
- SwiftData
- Swift Testing
- XCTest UI testing
- MVVM
- Clean Architecture

## Project Structure

```text
Swift Learn/
├── App/            # Composition root and dependency injection
├── Domain/         # Entities, contracts, and use cases
├── Data/           # Curriculum and persistence implementations
├── Presentation/   # SwiftUI views and view models
└── Assets.xcassets # App icons, launch assets, and Code Ascension identity
```

## Run the Project

1. Clone the repository.
2. Open `Swift Learn.xcodeproj` in Xcode.
3. Select the `Swift Learn` scheme.
4. Choose an iPhone, iPad, Mac, or Apple TV destination.
5. Build and run.

The project currently targets platform version 26.0 for iOS/iPadOS, macOS, and tvOS.

## Roadmap

Current product capabilities include:

- typed missing-code and output-prediction activities;
- spaced review based on attempts and mistakes;
- mastery tracking separate from lesson completion;
- boss challenges that combine skills from completed levels;
- guided projects that turn individual concepts into practical work;
- resume, level detail, canonical skill discovery, and adaptive supplemental practice;
- seven offline supplemental tracks for testing, architecture, persistence, security, professional practice, and release readiness.

Richer free-form editors and additional activity renderers remain future work. Current-build runtime verification is reported separately from implemented source.

## Code Ascension Identity

The Code Ascension logo represents progress through programming knowledge. The Swift bird communicates the language at the center of the journey, the surrounding form suggests levels and upward movement, and the **AT** signature identifies the creator.

Light, dark, transparent, macOS, tvOS, and Apple TV Top Shelf variants are included in the asset catalog.

## Author

**Ahmed Tarek**<br>
Senior iOS Developer<br>
[Portfolio](https://ahmedtarek-ios.github.io/me/) · [GitHub](https://github.com/ahmedtarek-ios)

## Copyright and Branding

Except for third-party marks and source material, original project content is copyright © 2026 Ahmed Tarek and distributed under the repository's MIT License.

Third-party source material keeps its original license and attribution. See `THIRD_PARTY_NOTICES.txt`.

The Swift name and Swift bird mark remain subject to the [Swift project trademark guidelines](https://www.swift.org/policies/).

---

<div align="center">
  <strong>Change code. See why it works. Use it again later.</strong>
  <br><br>
  Built with Swift by Ahmed Tarek.
</div>

<p align="center"><strong>In ❤️ of Swift</strong></p>
