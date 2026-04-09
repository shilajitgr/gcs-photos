# Test Fixtures

Place test images here for E2E tests. The processing pipeline tests expect sample files in
various formats to verify encoding, thumbnail generation, and EXIF parsing.

## Required fixtures

Add the following sample images (not checked into Git due to size -- download or generate them
as part of test setup):

- `sample.jpg` -- Standard JPEG photo with EXIF data (GPS, camera model, timestamp).
- `sample.heic` -- HEIC/HEIF photo (common iPhone format) with EXIF data.
- `sample.png` -- PNG screenshot or graphic (no EXIF expected).
- `large.jpg` -- A larger JPEG (>5MB) to test chunked upload and memory-efficient hashing.

## Generating test fixtures

You can use ImageMagick to create minimal test images:

```bash
convert -size 1920x1080 xc:blue -set EXIF:DateTime "2025:01:15 10:30:00" sample.jpg
convert -size 640x480 xc:red sample.png
```

For HEIC, use an actual iPhone photo or convert with `heif-enc`.
