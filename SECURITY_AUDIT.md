# Security Audit Report — TokenEater

**Date:** 2026-02-22
**Auditor:** Claude Opus 4.6 (automated)
**Repo:** https://github.com/AThevon/TokenEater (commit: main HEAD)
**Verdict:** PASS

---

## Summary Table

| # | Check | Status | Evidence |
|---|-------|--------|----------|
| 1 | Zero external dependencies | PASS | No Package.swift, Podfile, or Cartfile exists. Pure Swift + system frameworks only. |
| 2 | No known CVEs / security advisories | PASS | Web search for "TokenEater CVE security malware" returned zero results. |
| 3 | Dependency integrity | N/A | No dependencies to verify. |
| 4 | No reported security incidents | PASS | No community warnings, malware flags, or security incidents found online. |
| 5 | Network calls — only allowed destinations | PASS | Only `https://claude.ai` and `https://api.anthropic.com` — see details below. |
| 6 | Keychain access — documented, no exfiltration | PASS | Read-only access to Claude Code credentials and browser safe storage keys. |
| 7 | No hardcoded IPs or hidden endpoints | PASS | Only `127.0.0.1` as SOCKS proxy default (user-configurable). |
| 8 | No telemetry, analytics, or tracking | PASS | Zero analytics SDKs or tracking code found. |
| 9 | File system writes within expected scope | PASS | Writes only to Application Support (config/cache JSON files). |
| 10 | No obfuscated or encoded code | PASS | No base64, hex encoding, rot13, or encoded strings found. |
| 11 | SOCKS5 proxy routes to documented endpoints only | PASS | Proxy wraps the same URLSession used for claude.ai/api.anthropic.com calls. |
| 12 | No dynamic code loading | PASS | No dlopen, eval, NSAppleScript, Process(), NSTask, performSelector, or NSClassFromString. |
| 13 | No clipboard, screen recording, or accessibility access | PASS | No NSPasteboard, CGWindowList, CGDisplayStream, or AXUIElement usage. |
| 14 | Info.plist entitlements — expected only | PASS | Widget: sandbox + network.client. App: empty entitlements (not sandboxed). |

---

## Phase 2a: Dependency & Supply Chain Analysis

### Dependencies

**Zero external dependencies.** The project uses only:
- Swift standard library
- Apple system frameworks: Foundation, SwiftUI, WidgetKit, AppKit, Security, CommonCrypto, SQLite3, UserNotifications

No Package.swift, Podfile, Cartfile, or vendored libraries exist anywhere in the repository.

### Online Security Search

Web search for "TokenEater macOS security vulnerability CVE malware" returned no results related to this project. The only result was the GitHub repository itself.

---

## Phase 2b: Source Code Audit

### 5. Network Calls — Outbound Destinations

All network calls originate from `Shared/ClaudeAPIClient.swift`. Exactly two domains are contacted:

| Destination | Purpose | File:Line |
|-------------|---------|-----------|
| `https://claude.ai` | Cookie-based usage API (`/api/organizations/{orgId}/usage`) | `ClaudeAPIClient.swift:11,68,117` |
| `https://api.anthropic.com` | OAuth-based usage API (`/api/oauth/usage`) | `ClaudeAPIClient.swift:58,107` |

All requests are HTTP GET only. No POST, PUT, or upload calls exist anywhere in the codebase.

### 6. Keychain Access

| Operation | Service | Purpose | File:Line |
|-----------|---------|---------|-----------|
| Read | `"Claude Code-credentials"` | Read OAuth access token for API auth | `KeychainOAuthReader.swift:10-13` |
| Read | `"{Browser} Safe Storage"` (Chrome, Arc, Brave, Edge, Chromium) | Read browser encryption key to decrypt session cookies | `BrowserCookieReader.swift:135-139` |

All Keychain access is **read-only** (`SecItemCopyMatching`). No `SecItemAdd`, `SecItemUpdate`, or `SecItemDelete` calls exist. Credentials are used in-memory only to construct HTTP Authorization headers — never persisted to disk (except the session cookie values which the user explicitly imports via the UI).

### 7. Hardcoded URLs / IPs

| Value | Purpose | File:Line |
|-------|---------|-----------|
| `"https://claude.ai"` | API base URL | `ClaudeAPIClient.swift:11` |
| `"https://api.anthropic.com/api/oauth/usage"` | OAuth usage endpoint | `ClaudeAPIClient.swift:58,107` |
| `"127.0.0.1"` | Default SOCKS5 proxy host (user-configurable) | `UsageModels.swift:84` |
| `1080` | Default SOCKS5 proxy port (user-configurable) | `UsageModels.swift:84` |

No encoded or obfuscated URLs found.

### 8. Telemetry / Analytics

Zero analytics, crash reporting, or telemetry code. The `.tracking()` calls in widget views are SwiftUI font letter-spacing, not analytics tracking.

### 9. File System Writes

All file I/O is in `Shared/UsageModels.swift` (SharedStorage enum):

| Path | Purpose | File:Line |
|------|---------|-----------|
| `~/Library/Containers/{widget-bundle}/Data/Library/Application Support/claude-usage-config.json` | Persist user config (session key, org ID, proxy settings) | `UsageModels.swift:126-131,142-145` |
| `~/Library/Containers/{widget-bundle}/Data/Library/Application Support/claude-usage-cache.json` | Cache last usage response for offline widget display | `UsageModels.swift:133-137,155-157` |
| `/tmp/tokeneater_cookies_{UUID}.db` | Temporary SQLite copy for browser cookie reading (deleted in defer block) | `BrowserCookieReader.swift:192-220` |

All writes are within standard macOS app sandbox paths or temporary directories. The temp DB copy is cleaned up in a `defer` block.

### 10. Obfuscated / Encoded Code

No base64, hex encoding, rot13, or other encoding patterns found in any Swift file.

### 11. SOCKS5 Proxy Implementation

The proxy is configured in `ClaudeAPIClient.swift:21-29` as a standard `URLSessionConfiguration` SOCKS proxy. It wraps the same URLSession used for all API calls, meaning it can only route traffic to the two documented endpoints (claude.ai and api.anthropic.com). The proxy is disabled by default and only activated when the user explicitly enables it in Settings.

### 12. Dynamic Code Loading

No `dlopen`, `dlsym`, `eval`, `NSAppleScript`, `Process()`, `NSTask`, `performSelector`, `NSClassFromString`, `NSInvocation`, or `Bundle.init(url:)` calls found.

### 13. Clipboard / Screen / Accessibility

No `NSPasteboard`, `UIPasteboard`, `CGWindowList`, `CGDisplayStream`, `AXUIElement`, or `AXIsProcessTrusted` usage found.

### 14. Info.plist & Entitlements

**App entitlements** (`ClaudeUsageApp/ClaudeUsageApp.entitlements`):
- Empty `<dict/>` — the host app is **not sandboxed** (required to write into the widget's container and read browser cookies/Keychain).

**Widget entitlements** (`ClaudeUsageWidget/ClaudeUsageWidget.entitlements`):
- `com.apple.security.app-sandbox`: true (sandboxed)
- `com.apple.security.network.client`: true (outbound network access)

**No unexpected entitlements.** No camera, microphone, location, contacts, calendar, Bluetooth, or USB access requested.

**Widget Info.plist** (`ClaudeUsageWidget/Info.plist`):
- Standard WidgetKit extension point identifier: `com.apple.widgetkit-extension`
- No custom URL schemes or background modes.

---

## Conclusion

TokenEater is a clean, single-purpose macOS utility with **zero external dependencies**, **no telemetry**, and **no suspicious code patterns**. All network traffic goes exclusively to Anthropic's documented API endpoints. Keychain access is read-only and limited to credential retrieval for the app's stated purpose. File writes are confined to standard Application Support directories.

**Overall Verdict: PASS** — safe to build and install.
