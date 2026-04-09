# ADR-004: Flutter for Mobile + Web (Single Codebase)

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use Flutter for both mobile (Android + iOS) and web, delivering a single codebase across all platforms.

## Context
The app needs Play Store presence for discoverability and a web version for SEO/search presence. Users manage their photo galleries, trigger backups, and browse thumbnails.

### Alternatives Considered
| Option | Verdict |
|--------|---------|
| Flutter Mobile + Next.js Web | Best web performance/SEO via SSR, but two separate codebases |
| Flutter Mobile only | Simplest but no web discoverability |
| Flutter Mobile + Static landing page | No functional web app, limited to app store discovery |

## Consequences
- Single codebase: Android, iOS, and Web
- Shared UI components, state management, and business logic
- Flutter web bundle is larger than native web frameworks — acceptable tradeoff for code sharing
- SEO: pre-rendering possible via `flutter build web --web-renderer html`
- Web deployment: static assets to Firebase Hosting or Cloud Storage + Cloud CDN
- Play Store: signed AAB via GitHub Actions → Play Console
- iOS App Store: IPA → App Store Connect
