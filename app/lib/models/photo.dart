/// Domain model for a photo, mirroring the server-side schema.
///
/// This is a plain Dart class used throughout the app. The Drift table
/// ([PhotosTable]) handles persistence; this model is the app-level
/// representation.
class Photo {
  final String imageUid;
  final String exifKey;
  final String userId;
  final String? filePathGcs;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;
  final int? width;
  final int? height;
  final int? dateTaken;
  final String? cameraMake;
  final String? cameraModel;
  final int? iso;
  final double? aperture;
  final String? shutterSpeed;
  final double? focalLength;
  final double? latitude;
  final double? longitude;
  final String blurhash;
  final String? thumbSmHash;
  final String? thumbMdHash;
  final String? thumbLgHash;
  final String storageClass;
  final String? lifecycleRule;
  final String firestoreDocId;
  final int lastSyncedAt;
  final int syncVersion;
  final String backupStatus;
  final String? deviceOrigin;

  const Photo({
    required this.imageUid,
    required this.exifKey,
    required this.userId,
    this.filePathGcs,
    this.fileName,
    this.fileSize,
    this.mimeType,
    this.width,
    this.height,
    this.dateTaken,
    this.cameraMake,
    this.cameraModel,
    this.iso,
    this.aperture,
    this.shutterSpeed,
    this.focalLength,
    this.latitude,
    this.longitude,
    required this.blurhash,
    this.thumbSmHash,
    this.thumbMdHash,
    this.thumbLgHash,
    this.storageClass = 'STANDARD',
    this.lifecycleRule,
    required this.firestoreDocId,
    required this.lastSyncedAt,
    this.syncVersion = 0,
    this.backupStatus = 'pending',
    this.deviceOrigin,
  });

  Photo copyWith({
    String? imageUid,
    String? exifKey,
    String? userId,
    String? filePathGcs,
    String? fileName,
    int? fileSize,
    String? mimeType,
    int? width,
    int? height,
    int? dateTaken,
    String? cameraMake,
    String? cameraModel,
    int? iso,
    double? aperture,
    String? shutterSpeed,
    double? focalLength,
    double? latitude,
    double? longitude,
    String? blurhash,
    String? thumbSmHash,
    String? thumbMdHash,
    String? thumbLgHash,
    String? storageClass,
    String? lifecycleRule,
    String? firestoreDocId,
    int? lastSyncedAt,
    int? syncVersion,
    String? backupStatus,
    String? deviceOrigin,
  }) {
    return Photo(
      imageUid: imageUid ?? this.imageUid,
      exifKey: exifKey ?? this.exifKey,
      userId: userId ?? this.userId,
      filePathGcs: filePathGcs ?? this.filePathGcs,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      width: width ?? this.width,
      height: height ?? this.height,
      dateTaken: dateTaken ?? this.dateTaken,
      cameraMake: cameraMake ?? this.cameraMake,
      cameraModel: cameraModel ?? this.cameraModel,
      iso: iso ?? this.iso,
      aperture: aperture ?? this.aperture,
      shutterSpeed: shutterSpeed ?? this.shutterSpeed,
      focalLength: focalLength ?? this.focalLength,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      blurhash: blurhash ?? this.blurhash,
      thumbSmHash: thumbSmHash ?? this.thumbSmHash,
      thumbMdHash: thumbMdHash ?? this.thumbMdHash,
      thumbLgHash: thumbLgHash ?? this.thumbLgHash,
      storageClass: storageClass ?? this.storageClass,
      lifecycleRule: lifecycleRule ?? this.lifecycleRule,
      firestoreDocId: firestoreDocId ?? this.firestoreDocId,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      syncVersion: syncVersion ?? this.syncVersion,
      backupStatus: backupStatus ?? this.backupStatus,
      deviceOrigin: deviceOrigin ?? this.deviceOrigin,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUid': imageUid,
      'exifKey': exifKey,
      'userId': userId,
      'filePathGcs': filePathGcs,
      'fileName': fileName,
      'fileSize': fileSize,
      'mimeType': mimeType,
      'width': width,
      'height': height,
      'dateTaken': dateTaken,
      'cameraMake': cameraMake,
      'cameraModel': cameraModel,
      'iso': iso,
      'aperture': aperture,
      'shutterSpeed': shutterSpeed,
      'focalLength': focalLength,
      'latitude': latitude,
      'longitude': longitude,
      'blurhash': blurhash,
      'thumbSmHash': thumbSmHash,
      'thumbMdHash': thumbMdHash,
      'thumbLgHash': thumbLgHash,
      'storageClass': storageClass,
      'lifecycleRule': lifecycleRule,
      'firestoreDocId': firestoreDocId,
      'lastSyncedAt': lastSyncedAt,
      'syncVersion': syncVersion,
      'backupStatus': backupStatus,
      'deviceOrigin': deviceOrigin,
    };
  }

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      imageUid: json['imageUid'] as String,
      exifKey: json['exifKey'] as String,
      userId: json['userId'] as String,
      filePathGcs: json['filePathGcs'] as String?,
      fileName: json['fileName'] as String?,
      fileSize: json['fileSize'] as int?,
      mimeType: json['mimeType'] as String?,
      width: json['width'] as int?,
      height: json['height'] as int?,
      dateTaken: json['dateTaken'] as int?,
      cameraMake: json['cameraMake'] as String?,
      cameraModel: json['cameraModel'] as String?,
      iso: json['iso'] as int?,
      aperture: (json['aperture'] as num?)?.toDouble(),
      shutterSpeed: json['shutterSpeed'] as String?,
      focalLength: (json['focalLength'] as num?)?.toDouble(),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      blurhash: json['blurhash'] as String,
      thumbSmHash: json['thumbSmHash'] as String?,
      thumbMdHash: json['thumbMdHash'] as String?,
      thumbLgHash: json['thumbLgHash'] as String?,
      storageClass: json['storageClass'] as String? ?? 'STANDARD',
      lifecycleRule: json['lifecycleRule'] as String?,
      firestoreDocId: json['firestoreDocId'] as String,
      lastSyncedAt: json['lastSyncedAt'] as int,
      syncVersion: json['syncVersion'] as int? ?? 0,
      backupStatus: json['backupStatus'] as String? ?? 'pending',
      deviceOrigin: json['deviceOrigin'] as String?,
    );
  }
}
