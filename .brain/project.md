# Project

## Goal

A personal iPhone app that helps the user understand and plan their expenses. The first goal is a useful app running on the user's own iPhone, not an App Store release.

## Constraints

- Native iOS development using Xcode.
- Financial data stays in the app's local storage.
- No backend, account system, analytics, or cloud sync unless the user explicitly changes this direction.
- Keep the first version small and testable.
- Do not publish or distribute the app without an explicit request.

## Current state

The repository contains a native SwiftUI Xcode project with a provisional launch screen, unit/UI smoke tests, and no third-party dependencies. The finance model, persistence layer, and product workflows have not been designed or implemented.

## Development environment

- macOS with Xcode 27.2 confirmed on 2026-11-21.
- iOS 26.5 and 27.2 simulators are available.
- Physical-device deployment and Apple signing configuration are not yet confirmed.

## Working agreements

- The planner is the user's main point of contact.
- The developer implements approved feature notes and runs initial checks.
- The reviewer independently checks functionality and code quality.
- The planner reviews the completed handoff before committing and pushing.
- All durable project knowledge lives in this vault; source code and tests remain in their normal project locations.
