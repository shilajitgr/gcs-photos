import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../database/database.dart';
import 'blurhash_placeholder.dart';

/// A single photo tile in the gallery grid.
///
/// Shows a BlurHash placeholder while the thumbnail loads.
class PhotoTile extends StatelessWidget {
  final PhotosTableData photo;
  final VoidCallback? onTap;

  const PhotoTile({
    super.key,
    required this.photo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbHash = photo.thumbSmHash ?? photo.thumbMdHash;
    final imageUrl = thumbHash != null
        ? '${AppConfig.apiBaseUrl}/thumb/${thumbHash}_sm.avif'
        : null;

    return GestureDetector(
      onTap: onTap,
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  BlurHashPlaceholder(hash: photo.blurhash),
              errorWidget: (context, url, error) =>
                  BlurHashPlaceholder(hash: photo.blurhash),
            )
          : BlurHashPlaceholder(hash: photo.blurhash),
    );
  }
}
