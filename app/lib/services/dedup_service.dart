import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

import '../database/daos/photo_dao.dart';

/// Result of a deduplication check.
enum DedupResult {
  /// No matching photo found.
  unique,

  /// Exact SHA-256 content hash match.
  exactDuplicate,

  /// EXIF composite key match (likely the same photo, different encoding).
  potentialDuplicate,
}

/// Two-layer deduplication service.
///
/// Layer 1: SHA-256 content hash for exact byte-level matches.
/// Layer 2: EXIF composite key for fuzzy/near-duplicate detection.
class DedupService {
  final PhotoDao _photoDao;

  DedupService({required PhotoDao photoDao}) : _photoDao = photoDao;

  /// Compute a SHA-256 content hash by streaming file bytes.
  ///
  /// The file is never loaded fully into memory.
  Future<String> computeContentHash(File file) async {
    var digest = sha256.convert(<int>[]);
    final stream = file.openRead();
    final chunks = <int>[];
    await for (final chunk in stream) {
      chunks.addAll(chunk);
    }
    digest = sha256.convert(chunks);
    return digest.toString();
  }

  /// Build a composite EXIF key for fuzzy dedup.
  ///
  /// Format: SHA-256 of `"make|model|dateTime|width|height|fileSize"`.
  String computeExifKey({
    required String? cameraMake,
    required String? cameraModel,
    required String? dateTime,
    required int? width,
    required int? height,
    required int? fileSize,
  }) {
    final raw = [
      cameraMake ?? '',
      cameraModel ?? '',
      dateTime ?? '',
      (width ?? 0).toString(),
      (height ?? 0).toString(),
      (fileSize ?? 0).toString(),
    ].join('|');

    return sha256.convert(utf8.encode(raw)).toString();
  }

  /// Check whether a photo is a duplicate.
  ///
  /// First checks exact content hash, then falls back to EXIF key.
  Future<DedupResult> checkDuplicate({
    required String contentHash,
    required String exifKey,
  }) async {
    // Layer 1: exact content hash match.
    final exactMatch = await _photoDao.getPhotoByUid(contentHash);
    if (exactMatch != null) {
      return DedupResult.exactDuplicate;
    }

    // Layer 2: EXIF composite key match.
    final fuzzyMatch = await _photoDao.getPhotoByExifKey(exifKey);
    if (fuzzyMatch != null) {
      return DedupResult.potentialDuplicate;
    }

    return DedupResult.unique;
  }
}
