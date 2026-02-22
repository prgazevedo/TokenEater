# Homebrew Cask + CI/CD Pipeline Design

**Goal:** Distribute TokenEater via Homebrew Cask with automated releases.

**Architecture:** Personal Homebrew tap (`AThevon/homebrew-tokeneater`) + GitHub Actions pipeline on the main repo triggered by version tags.

## Components

### 1. Homebrew Tap Repository

New repo: `github.com/AThevon/homebrew-tokeneater`

Single file: `Casks/tokeneater.rb` — standard Homebrew Cask definition pointing to the GitHub release DMG. Includes `postflight` for `xattr -cr` (app is not notarized).

### 2. CI/CD Pipeline

Workflow: `.github/workflows/release.yml` on `AThevon/TokenEater`

Trigger: Push tag matching `v*`

Steps:
1. macOS runner
2. Install XcodeGen
3. Generate Xcode project + fix NSExtension in Info.plist
4. Build Release with xcodebuild
5. Create DMG with hdiutil
6. Create GitHub release with DMG artifact
7. Compute SHA256
8. Update Cask in homebrew-tokeneater (version + sha256)

Secret required: `HOMEBREW_TAP_TOKEN` (PAT with `repo` scope)

### 3. README Update

Add Homebrew install section as primary install method in Quick Install.

## User Experience

```bash
# Install
brew tap AThevon/tokeneater
brew install --cask tokeneater

# Update
brew upgrade tokeneater
```

## Developer Experience

```bash
# Release
git tag v1.3.0
git push origin v1.3.0
# Everything else is automated
```
