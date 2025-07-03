import 'dart:io';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for storage operations
class StorageService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Upload file to storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required File file,
    Map<String, String>? metadata,
  }) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .upload(path, file, fileOptions: FileOptions(metadata: metadata));

      return response;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Upload file from bytes
  Future<String> uploadBytes({
    required String bucket,
    required String path,
    required Uint8List bytes,
    String? contentType,
    Map<String, String>? metadata,
  }) async {
    try {
      final response = await _supabase.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: contentType,
              metadata: metadata,
            ),
          );

      return response;
    } catch (e) {
      throw Exception('Failed to upload bytes: $e');
    }
  }

  /// Get public URL for a file
  String getPublicUrl({
    required String bucket,
    required String path,
  }) {
    return _supabase.storage.from(bucket).getPublicUrl(path);
  }

  /// Get signed URL for a file
  Future<String> getSignedUrl({
    required String bucket,
    required String path,
    int expiresIn = 3600, // 1 hour default
  }) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .createSignedUrl(path, expiresIn);

      return response;
    } catch (e) {
      throw Exception('Failed to get signed URL: $e');
    }
  }

  /// Download file
  Future<List<int>> downloadFile({
    required String bucket,
    required String path,
  }) async {
    try {
      final response = await _supabase.storage.from(bucket).download(path);
      return response;
    } catch (e) {
      throw Exception('Failed to download file: $e');
    }
  }

  /// Delete file
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove([path]);
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Delete multiple files
  Future<void> deleteFiles({
    required String bucket,
    required List<String> paths,
  }) async {
    try {
      await _supabase.storage.from(bucket).remove(paths);
    } catch (e) {
      throw Exception('Failed to delete files: $e');
    }
  }

  /// List files in a directory
  Future<List<FileObject>> listFiles({
    required String bucket,
    String? path,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase.storage.from(bucket).list(
            path: path,
            searchOptions: SearchOptions(
              limit: limit,
              offset: offset,
            ),
          );

      return response;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  /// Move file
  Future<String> moveFile({
    required String bucket,
    required String fromPath,
    required String toPath,
  }) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .move(fromPath, toPath);

      return response;
    } catch (e) {
      throw Exception('Failed to move file: $e');
    }
  }

  /// Copy file
  Future<String> copyFile({
    required String bucket,
    required String fromPath,
    required String toPath,
  }) async {
    try {
      final response = await _supabase.storage
          .from(bucket)
          .copy(fromPath, toPath);

      return response;
    } catch (e) {
      throw Exception('Failed to copy file: $e');
    }
  }

  /// Get file info
  Future<FileObject> getFileInfo({
    required String bucket,
    required String path,
  }) async {
    try {
      final files = await _supabase.storage.from(bucket).list(path: path);
      if (files.isEmpty) {
        throw Exception('File not found');
      }
      return files.first;
    } catch (e) {
      throw Exception('Failed to get file info: $e');
    }
  }
}
