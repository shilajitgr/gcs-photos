package resize

import (
	"fmt"

	"github.com/davidbyttow/govips/v2/vips"
)

func init() {
	vips.Startup(nil)
}

// Process resizes image data to the given width and encodes it in the requested format.
// Supported formats: avif, webp, jpeg.
func Process(data []byte, width int, format string) ([]byte, string, error) {
	image, err := vips.NewImageFromBuffer(data)
	if err != nil {
		return nil, "", fmt.Errorf("decode: %w", err)
	}
	defer image.Close()

	if err := image.Thumbnail(width, 10000, vips.InterestingNone); err != nil {
		return nil, "", fmt.Errorf("resize: %w", err)
	}

	switch format {
	case "avif":
		params := vips.NewAvifExportParams()
		params.Quality = 80
		out, _, err := image.ExportAvif(params)
		if err != nil {
			return nil, "", fmt.Errorf("encode avif: %w", err)
		}
		return out, "image/avif", nil

	case "webp":
		params := vips.NewWebpExportParams()
		params.Quality = 82
		out, _, err := image.ExportWebp(params)
		if err != nil {
			return nil, "", fmt.Errorf("encode webp: %w", err)
		}
		return out, "image/webp", nil

	case "jpeg":
		params := vips.NewJpegExportParams()
		params.Quality = 85
		out, _, err := image.ExportJpeg(params)
		if err != nil {
			return nil, "", fmt.Errorf("encode jpeg: %w", err)
		}
		return out, "image/jpeg", nil

	default:
		return nil, "", fmt.Errorf("unsupported format: %s", format)
	}
}
