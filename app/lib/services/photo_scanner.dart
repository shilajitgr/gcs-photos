import 'dart:io';

import 'package:photo_manager/photo_manager.dart';

/// Scans the device photo library for assets to back up.
class PhotoScanner {
  /// Request permission and return all photo assets from the device.
  ///
  /// Returns an empty list if permission is denied.
  Future<List<AssetEntity>> scanDevicePhotos() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth) {
      return [];
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      hasAll: true,
    );

    if (albums.isEmpty) return [];

    // Use the "all" album (first entry when hasAll is true).
    final allAlbum = albums.first;
    final count = await allAlbum.assetCountAsync;

    // Page through all assets.
    final assets = <AssetEntity>[];
    const pageSize = 100;
    for (var page = 0; page * pageSize < count; page++) {
      final pageAssets = await allAlbum.getAssetListPaged(
        page: page,
        size: pageSize,
      );
      assets.addAll(pageAssets);
    }

    return assets;
  }

  /// Get the [File] handle for an [AssetEntity].
  ///
  /// Returns `null` if the file is not available.
  Future<File?> getFile(AssetEntity asset) async {
    return asset.file;
  }
}
