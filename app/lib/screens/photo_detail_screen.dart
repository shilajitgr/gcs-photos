import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../providers/photos_provider.dart';
import '../widgets/blurhash_placeholder.dart';

class PhotoDetailScreen extends ConsumerWidget {
  final String photoId;

  const PhotoDetailScreen({super.key, required this.photoId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photosAsync = ref.watch(photosProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: photosAsync.when(
        data: (photos) {
          final photo = photos.where((p) => p.imageUid == photoId).firstOrNull;
          if (photo == null) {
            return const Center(
              child: Text(
                'Photo not found',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final thumbHash = photo.thumbLgHash ?? photo.thumbMdHash;
          final imageUrl = thumbHash != null
              ? '${AppConfig.apiBaseUrl}/thumb/${thumbHash}_lg.avif'
              : null;

          return Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) =>
                          BlurHashPlaceholder(hash: photo.blurhash),
                      errorWidget: (context, url, error) =>
                          BlurHashPlaceholder(hash: photo.blurhash),
                    )
                  : BlurHashPlaceholder(hash: photo.blurhash),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text(
            'Error: $error',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
