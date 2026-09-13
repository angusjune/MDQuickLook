# Ad-hoc signed, distributed via Homebrew cask without notarization

There is no paid Apple Developer account. The app ships as an ad-hoc signed CI build (GitHub Actions on tag → `xcodebuild` → zip on GitHub Releases) consumed by a cask in `angusjune/homebrew-tap`, with the cask JSON updated manually at first. This works because `brew install --cask` does not set the quarantine attribute, so Gatekeeper never blocks the download. The open risk — whether macOS loads a QuickLook extension that is only ad-hoc signed — is validated as the project's first milestone spike; if it fails (or distribution widens), escalate to Developer ID + notarization.

Consequence: releases from this repo run on machines that install via the tap; arbitrary copy-out-of-DMG distribution is not supported by this decision.
