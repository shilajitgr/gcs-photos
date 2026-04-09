import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:drift/drift.dart';

import '../database/database.dart';
import '../database/daos/photo_dao.dart';
import '../database/daos/sync_dao.dart';
import '../models/photo.dart';
import 'api_service.dart';

/// Manages full (paginated) and incremental (Firestore onSnapshot) sync.
class SyncService {
  final ApiService _apiService;
  final PhotoDao _photoDao;
  final SyncDao _syncDao;
  final FirebaseFirestore _firestore;

  SyncService({
    required ApiService apiService,
    required PhotoDao photoDao,
    required SyncDao syncDao,
    FirebaseFirestore? firestore,
  })  : _apiService = apiService,
        _photoDao = photoDao,
        _syncDao = syncDao,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Perform a full paginated sync from the Cloud Run API.
  ///
  /// Used on fresh login or when the local DB is empty.
  Future<void> fullSync(String userId) async {
    String? cursor;
    var totalSynced = 0;

    do {
      final response = await _apiService.syncPhotos(
        mode: 'full',
        cursor: cursor,
      );

      final data = response.data as Map<String, dynamic>;
      final photos = (data['photos'] as List<dynamic>)
          .map((e) => Photo.fromJson(e as Map<String, dynamic>))
          .toList();

      // Batch insert into local DB via the DAO.
      await _photoDao.insertPhotoBatch(
        photos.map((p) => _photoToCompanion(p)).toList(),
      );

      totalSynced += photos.length;
      cursor = data['nextCursor'] as String?;
    } while (cursor != null);

    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await _syncDao.updateSyncState(
      userId: userId,
      timestamp: now,
      totalSynced: totalSynced,
    );
  }

  /// Start incremental sync via Firestore onSnapshot listener.
  ///
  /// Returns a function that cancels the listener.
  Future<void Function()> startIncrementalSync(String userId) async {
    final syncState = await _syncDao.getSyncState(userId);
    final lastSync = syncState?.lastFullSync ?? 0;

    final subscription = _firestore
        .collection('users')
        .doc(userId)
        .collection('photos')
        .where('updatedAt', isGreaterThan: lastSync)
        .snapshots()
        .listen((snapshot) async {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) continue;

        final data = change.doc.data();
        if (data == null) continue;

        final photo = Photo.fromJson({...data, 'firestoreDocId': change.doc.id});
        await _photoDao.insertPhoto(_photoToCompanion(photo));
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      await _syncDao.updateSyncState(userId: userId, timestamp: now);
    });

    return subscription.cancel;
  }

  PhotosTableCompanion _photoToCompanion(Photo photo) {
    return PhotosTableCompanion(
      imageUid: Value(photo.imageUid),
      exifKey: Value(photo.exifKey),
      userId: Value(photo.userId),
      filePathGcs: Value(photo.filePathGcs),
      fileName: Value(photo.fileName),
      fileSize: Value(photo.fileSize),
      mimeType: Value(photo.mimeType),
      width: Value(photo.width),
      height: Value(photo.height),
      dateTaken: Value(photo.dateTaken),
      cameraMake: Value(photo.cameraMake),
      cameraModel: Value(photo.cameraModel),
      iso: Value(photo.iso),
      aperture: Value(photo.aperture),
      shutterSpeed: Value(photo.shutterSpeed),
      focalLength: Value(photo.focalLength),
      latitude: Value(photo.latitude),
      longitude: Value(photo.longitude),
      blurhash: Value(photo.blurhash),
      thumbSmHash: Value(photo.thumbSmHash),
      thumbMdHash: Value(photo.thumbMdHash),
      thumbLgHash: Value(photo.thumbLgHash),
      storageClass: Value(photo.storageClass),
      lifecycleRule: Value(photo.lifecycleRule),
      firestoreDocId: Value(photo.firestoreDocId),
      lastSyncedAt: Value(DateTime.now().millisecondsSinceEpoch ~/ 1000),
      syncVersion: Value(photo.syncVersion),
      backupStatus: Value(photo.backupStatus),
      deviceOrigin: Value(photo.deviceOrigin),
    );
  }
}
