import 'dart:io';
import 'dart:typed_data';

import 'package:file_browser/features/file_browser/data/models/file_item.dart';
import 'package:file_browser/features/file_browser/domain/repositories/file_repository.dart';
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path/path.dart' as path;
import 'package:rxdart/rxdart.dart';

class FtpRepository implements FileRepository {
  final String host;
  final int port;
  final String username;
  final String password;
  final bool useFtps;
  final FTPConnect _client;
  bool _isConnected = false;
  
  FtpRepository({
    required this.host,
    required this.port,
    required this.username,
    required this.password,
    this.useFtps = false,
  }) : _client = FTPConnect(
          host,
          port: port,
          user: username,
          pass: password,
          timeout: 30,
          securityType: useFtps ? SecurityType.FTPS : SecurityType.FTP,
          debug: false,
        );

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> connect() async {
    try {
      _isConnected = await _client.connect();
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    if (_isConnected) {
      await _client.disconnect();
      _isConnected = false;
    }
  }

  @override
  Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      // FTP doesn't have a direct copy command, so we download and then upload
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/temp_file');
      
      // Download the source file
      await _client.downloadFile(sourcePath, tempFile);
      
      // Upload to destination
      await _client.uploadFile(tempFile, destinationPath);
      
      // Clean up
      await tempFile.delete();
      await tempDir.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> createDirectory(String path) async {
    try {
      return await _client.makeDirectory(path);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    try {
      return await _client.deleteDirectory(path);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      return await _client.deleteFile(path);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Stream<double>> downloadFile(String remotePath, String localPath) async {
    final controller = BehaviorSubject<double>();
    
    try {
      final file = File(localPath);
      
      // Set up progress callback
      final progressCallback = (double progress) {
        controller.add(progress);
      };
      
      await _client.downloadFileWithProgress(remotePath, file, progressCallback);
      
      controller.add(1.0);
      await controller.close();
    } catch (e) {
      controller.addError(e);
    }
    
    return controller.stream;
  }

  @override
  Future<FileItem> getFileDetails(String path) async {
    try {
      final isDir = await _client.isDirectory(path);
      final ftpEntry = await _getFTPEntryDetail(path);
      
      return _convertToFileItem(ftpEntry, path, isDir);
    } catch (e) {
      throw Exception('Failed to get file details: $e');
    }
  }
  
  Future<FTPEntry?> _getFTPEntryDetail(String filePath) async {
    try {
      final dirPath = path.dirname(filePath);
      final fileName = path.basename(filePath);
      
      final dirContent = await _client.listDirectoryContent(dirPath);
      return dirContent.firstWhere((entry) => entry.name == fileName);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, String>> getFileProperties(String path) async {
    try {
      final ftpEntry = await _getFTPEntryDetail(path);
      
      if (ftpEntry != null) {
        return {
          'name': ftpEntry.name,
          'size': ftpEntry.size.toString(),
          'modifiedTime': ftpEntry.modifyTime?.toIso8601String() ?? '',
          'permissions': ftpEntry.permissions ?? '',
          'type': ftpEntry.type.toString(),
        };
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  @override
  Future<int> getFreeSpace() async {
    // FTP doesn't provide a standard way to get free space
    return -1;
  }

  @override
  Future<int> getTotalSpace() async {
    // FTP doesn't provide a standard way to get total space
    return -1;
  }

  @override
  Future<List<FileItem>> listFiles(String directoryPath) async {
    try {
      final entries = await _client.listDirectoryContent(directoryPath);
      
      return entries.map((entry) {
        final entryPath = directoryPath.endsWith('/') 
            ? '$directoryPath${entry.name}' 
            : '$directoryPath/${entry.name}';
            
        return _convertToFileItem(entry, entryPath, entry.type == FTPEntryType.DIR);
      }).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> lockFile(String path, {Duration? timeout}) async {
    // FTP doesn't support file locking
    return false;
  }

  @override
  Future<bool> moveFile(String sourcePath, String destinationPath) async {
    try {
      // FTP doesn't have a direct move command, so we download and then upload
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/temp_file');
      
      // Download the source file
      await _client.downloadFile(sourcePath, tempFile);
      
      // Upload to destination
      await _client.uploadFile(tempFile, destinationPath);
      
      // Delete the original
      await _client.deleteFile(sourcePath);
      
      // Clean up
      await tempFile.delete();
      await tempDir.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Uint8List> readFile(String path) async {
    try {
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/temp_file');
      
      // Download the file
      await _client.downloadFile(path, tempFile);
      
      // Read the file content
      final bytes = await tempFile.readAsBytes();
      
      // Clean up
      await tempFile.delete();
      await tempDir.delete();
      
      return bytes;
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  @override
  Future<bool> renameFile(String path, String newName) async {
    try {
      final dirPath = path.substring(0, path.lastIndexOf('/'));
      final newPath = '$dirPath/$newName';
      
      return await _client.rename(path, newPath);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<FileItem>> searchFiles(String query, {String? path}) async {
    final searchPath = path ?? '/';
    final allFiles = <FileItem>[];
    
    try {
      await _searchRecursive(searchPath, query.toLowerCase(), allFiles);
      return allFiles;
    } catch (e) {
      return [];
    }
  }

  Future<void> _searchRecursive(String currentPath, String query, List<FileItem> results) async {
    try {
      final entries = await _client.listDirectoryContent(currentPath);
      
      for (final entry in entries) {
        final entryPath = currentPath.endsWith('/') 
            ? '$currentPath${entry.name}' 
            : '$currentPath/${entry.name}';
            
        final isDir = entry.type == FTPEntryType.DIR;
        final fileItem = _convertToFileItem(entry, entryPath, isDir);
        
        if (fileItem.name.toLowerCase().contains(query)) {
          results.add(fileItem);
        }
        
        if (isDir && !entry.name.startsWith('.')) {
          await _searchRecursive(entryPath, query, results);
        }
      }
    } catch (e) {
      // Skip this directory if there's an error
    }
  }

  @override
  Future<bool> setFileProperties(String path, Map<String, String> properties) async {
    // FTP doesn't support setting arbitrary properties
    return false;
  }

  @override
  Future<bool> unlockFile(String path) async {
    // FTP doesn't support file locking
    return false;
  }

  @override
  Future<Stream<double>> uploadFile(String localPath, String remotePath) async {
    final controller = BehaviorSubject<double>();
    
    try {
      final file = File(localPath);
      
      // Set up progress callback
      final progressCallback = (double progress) {
        controller.add(progress);
      };
      
      await _client.uploadFileWithProgress(file, remotePath, progressCallback);
      
      controller.add(1.0);
      await controller.close();
    } catch (e) {
      controller.addError(e);
    }
    
    return controller.stream;
  }

  @override
  Future<bool> writeFile(String path, Uint8List data) async {
    try {
      final tempDir = await Directory.systemTemp.createTemp();
      final tempFile = File('${tempDir.path}/temp_file');
      
      // Write data to temp file
      await tempFile.writeAsBytes(data);
      
      // Upload the file
      await _client.uploadFile(tempFile, path);
      
      // Clean up
      await tempFile.delete();
      await tempDir.delete();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> cancelTransfer(String path) async {
    // FTP client doesn't directly support cancelling transfers
    return false;
  }

  FileItem _convertToFileItem(FTPEntry entry, String filePath, bool isDirectory) {
    final name = entry.name;
    
    final FileType type = isDirectory
        ? FileType.folder
        : FileItem.getFileTypeFromExtension(filePath);
    
    return FileItem(
      id: filePath,
      name: name,
      path: filePath,
      type: type,
      source: FileSource.ftp,
      isDirectory: isDirectory,
      modifiedDate: entry.modifyTime,
      size: entry.size,
      mimeType: null,
      metadata: {
        'permissions': entry.permissions,
      },
    );
  }
}
