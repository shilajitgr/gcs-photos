import 'package:flutter/material.dart';

import '../database/database.dart';
import 'photo_tile.dart';

/// Responsive photo grid that adapts column count to screen width.
class PhotoGrid extends StatelessWidget {
  final List<PhotosTableData> photos;
  final void Function(PhotosTableData photo)? onPhotoTap;

  const PhotoGrid({
    super.key,
    required this.photos,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = _columnCount(constraints.maxWidth);
        return GridView.builder(
          padding: const EdgeInsets.all(2),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            return PhotoTile(
              photo: photo,
              onTap: () => onPhotoTap?.call(photo),
            );
          },
        );
      },
    );
  }

  /// Determine column count based on available width.
  int _columnCount(double width) {
    if (width >= 900) return 6;
    if (width >= 600) return 4;
    return 3;
  }
}
