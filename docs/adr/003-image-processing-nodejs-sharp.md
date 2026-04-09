# ADR-003: Node.js + Sharp for Image Processing Pipeline

**Status:** Accepted
**Date:** 2026-04-09

## Decision
Use Node.js (TypeScript) with Sharp (libvips) for the Cloud Run Jobs image processing pipeline.

## Context
The pipeline handles AVIF/WebP encoding, multi-size thumbnail generation, EXIF parsing, and BlurHash generation. It runs as Cloud Run Jobs with 24-hour timeout.

### Alternatives Considered
| Option | Verdict |
|--------|---------|
| Go + libvips (bimg) | Fast, low memory, but CGo adds Docker build complexity |
| Python + Pillow/pillow-avif | Simple but slower; higher memory; AVIF support via plugins |
| Rust + image-rs | Maximum performance but higher development complexity |

## Consequences
- Sharp wraps libvips — fastest image processing available in Node.js
- Native AVIF and WebP support out of the box
- EXIF extraction via Sharp's built-in metadata API (exif-reader)
- BlurHash generation via `blurhash` npm package
- SHA-256 content-hash via Node.js `crypto` module
- TypeScript provides type safety across the pipeline
- Same runtime as Cloud Functions event glue — shared tooling and patterns

### Thumbnail Variants Generated
| Variant | Format | Size | Use Case |
|---------|--------|------|----------|
| `thumb_sm` | AVIF | 200px wide | Gallery grid view |
| `thumb_md` | AVIF | 600px wide | Detail view preview |
| `thumb_lg` | AVIF | 1200px wide | Full-screen view on mobile |
| `thumb_xl` | WebP | 1200px wide | Browsers without AVIF support |
| `original` | Preserved | Original | Download / full-res view |
