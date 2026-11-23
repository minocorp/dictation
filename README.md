# Dictation

Hold-to-talk dictation for macOS that transcribes and cleans up speech on the device and inserts the text into the focused app. "Dictation" is a working name.

## Requirements

- Apple Silicon Mac
- macOS 26 or later
- Xcode 27 or later with the Metal toolchain (`xcodebuild -downloadComponent MetalToolchain`)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) only when `project.yml` changes (`xcodegen generate`)
- [SwiftLint](https://github.com/realm/SwiftLint) for the checks

## Build and install

Create `Config/Local.xcconfig` (gitignored) with your signing team:

```
DEVELOPMENT_TEAM = <your team id>
CODE_SIGN_STYLE = Automatic
CODE_SIGN_IDENTITY = Apple Development
```

Then:

```
scripts/install
```

It builds a Release app into `run/dd-release`, copies it to `~/Applications/Dictation.app` and opens it. Without a `Local.xcconfig` the app is ad-hoc signed, and macOS may ask for Accessibility and Microphone access again after each rebuild.

## Layout

```
App/                 app target: composition root, AppKit shells
Packages/Dictation/  core, features and UI (`swift test`)
Packages/EnginesMLX/ MLX engines (built with xcodebuild)
Eval/                evaluation CLI
Models/              curated model manifest
Config/              xcconfigs, formatter and linter config
scripts/             install, check-deps
run/                 scratch output (gitignored)
```

The product name is set in `project.yml` and `Config/Base.xcconfig` (`PRODUCT_NAME`, `PRODUCT_BUNDLE_IDENTIFIER`).

## Checks

```
swift format lint --strict --recursive Packages App Eval
swiftlint lint --strict
scripts/check-deps
swift test --package-path Packages/Dictation
```

`Packages/EnginesMLX` and `Eval` need `xcodebuild test -scheme <EnginesMLX or Eval> -destination platform=macOS` from their directories.

## License

Apache-2.0. See [LICENSE](LICENSE) and [NOTICE](NOTICE).
