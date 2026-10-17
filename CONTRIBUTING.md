# Contributing to Soniq

Thanks for helping make Soniq better!

## Reporting bugs

[Open an issue](https://github.com/webdevpls/soniq/issues/new?template=bug_report.md) and include:

- Your macOS version and Mac model (Apple silicon or Intel)
- Your output device (built-in speakers, AirPods, USB interface…)
- What you did, what you expected and what happened
- The affected app, if the problem is with one app

Logs help a lot. Run Soniq with diagnostics and attach the output:

```sh
open --env SONIQ_DEBUG=1 --stderr ~/Desktop/soniq.log /Applications/Soniq.app
```

## Suggesting features

[Open a feature request](https://github.com/webdevpls/soniq/issues/new?template=feature_request.md).
Describe the problem first, then the solution you have in mind.

## Pull requests

1. Fork the repository and create a branch from `main`.
2. Build with `./scripts/build-app.sh` and test the change in the real app.
3. Keep the code style of the surrounding files: SwiftUI, small views, comments only where the reason isn't obvious.
4. Code on the realtime audio thread (`AppTap.render`, `EffectsProcessor.process`, `Limiter`) must not allocate memory, take locks or call Objective-C.
5. Describe what you changed and how you tested it.

By contributing you agree that your contribution is licensed under the [GPL-3.0](LICENSE).
