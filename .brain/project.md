# Project

## Goal

A personal iPhone app that helps the user understand and plan their expenses. The first goal is a useful app running on the user's own iPhone, not an App Store release.

## Constraints

- Native iOS development using Xcode.
- Financial data stays in the app's local storage.
- No backend, account system, analytics, or cloud sync unless the user explicitly changes this direction.
- Public exchange-rate requests are allowed, but they must not contain financial data; cached and manual rates support offline use.
- Keep the first version small and testable.
- Do not publish or distribute the app without an explicit request.

## Current state

The repository contains a native SwiftUI/Xcode project, SwiftData finance models, a pure Decimal budget engine, a validated CNY/COP exchange-rate service with local caching and manual fallback, and unit/UI tests with no third-party dependencies. The provisional launch screen is unchanged; production finance workflows and exchange-rate selection UI are not implemented yet.

## Development environment

- macOS with Xcode 27.2 confirmed on 2026-11-21.
- iOS 26.5 and 27.2 simulators are available.
- Target personal device: iPhone 16 Pro with iOS 26.6.2; physical deployment and Apple signing configuration are not yet confirmed.

## Working agreements

- The planner is the user's main point of contact.
- The developer implements approved feature notes and runs initial checks.
- The reviewer independently checks functionality and code quality.
- The planner reviews the completed handoff before committing and pushing.
- All durable project knowledge lives in this vault; source code and tests remain in their normal project locations.
