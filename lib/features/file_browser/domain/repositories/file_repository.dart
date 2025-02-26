import 'dart:typed_data';
import 'package:file_browser/core/services/logger_service.dart';
import 'package:file_browser/features/file_browser/data/models/file_item.dart';

class FileOperationException implements Exception {
  final String message;
  final dynamic originalError;

  FileOperationException(this.message, [this.originalError]);

  @override
  String toString() => 'FileOperationException: $message${originalError != null ? '\nOriginal error: $originalError' : ''}';
}

abstract class FileRepository {
  /// Connection methods
  Future<bool> connect() async {
    if (isConnected) {
      LoggerService.debug('Already connected');
      return true;
    }
    try {
      final result = await initializeConnection();
      LoggerService.info('Connection ${result ? 'successful' : 'failed'}');
      return result;
    } catch (e) {
      LoggerService.error('Connection failed', e);
      throw FileOperationException('Failed to connect', e);
    }
  }
  
  /// Implement this method to handle actual connection logic
  Future<bool> initializeConnection();
  Future<void> disconnect();
  bool get isConnected;
  
  /// Basic file operations
  Future<List<FileItem>> listFiles(String path);
  Future<FileItem> getFileDetails(String path);
  Future<Uint8List> readFile(String path);
  Future<bool> writeFile(String path, Uint8List data);
  Future<bool> createDirectory(String path);
  Future<bool> deleteFile(String path);
  Future<bool> deleteDirectory(String path);
  Future<bool> moveFile(String sourcePath, String destinationPath);
  Future<bool> copyFile(String sourcePath, String destinationPath);
  Future<bool> renameFile(String path, String newName);
  
  /// Search functionality
  Future<List<FileItem>> searchFiles(String query, {String? path});
  
  /// Advanced operations
  Future<Stream<double>> downloadFile(String remotePath, String localPath);
  Future<Stream<double>> uploadFile(String localPath, String remotePath);
  Future<bool> cancelTransfer(String path);
  
  /// Optional WebDAV specific operations
  Future<bool> lockFile(String path, {Duration? timeout});
  Future<bool> unlockFile(String path);
  Future<Map<String, String>> getFileProperties(String path);
  Future<bool> setFileProperties(String path, Map<String, String> properties);
  
  /// Utilities
  Future<int> getFreeSpace();
  Future<int> getTotalSpace();
}
