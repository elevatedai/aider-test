import 'dart:io';
import 'dart:typed_data';

import 'package:file_browser/features/file_browser/data/models/file_item.dart';
import 'package:file_browser/features/file_browser/domain/repositories/file_repository.dart';
import 'package:path/path.dart' as filepath;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

class LocalRepository implements FileRepository {
  String? _rootPath;
  bool _isConnected = false;

  LocalRepository();

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> connect() async {
    try {
      await _requestPermissions();
      await _initRootPath();
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Storage permission is required');
      }
    }
  }

  Future<void> _initRootPath() async {
    if (Platform.isAndroid) {
      final directory = await getExternalStorageDirectory();
      _rootPath = directory?.path;
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      _rootPath = directory.path;
    } else {
      final directory = await getApplicationDocumentsDirectory();
      _rootPath = directory.path;
    }
    
    if (_rootPath == null) {
      throw Exception('Could not initialize root path');
    }
  }

  String _getAbsolutePath(String relativePath) {
    if (relativePath == '/') {
      return _rootPath!;
    }
    
    String formattedPath = relativePath.startsWith('/') ? relativePath.substring(1) : relativePath;
    return filepath.join(_rootPath!, formattedPath);
  }

  String _getRelativePath(String absolutePath) {
    if (absolutePath == _rootPath) {
      return '/';
    }
    
    final relative = filepath.relative(absolutePath, from: _rootPath!);
    return '/$relative';
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
  }

  @override
  Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(_getAbsolutePath(sourcePath));
      final destFile = File(_getAbsolutePath(destinationPath));
      
      await sourceFile.copy(destFile.path);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> createDirectory(String path) async {
    try {
      final directory = Directory(_getAbsolutePath(path));
      await directory.create(recursive: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    try {
      final directory = Directory(_getAbsolutePath(path));
      await directory.delete(recursive: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      final file = File(_getAbsolutePath(path));
      await file.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Stream<double>> downloadFile(String remotePath, String localPath) async {
    final controller = BehaviorSubject<double>();
    
    try {
      final sourceFile = File(_getAbsolutePath(remotePath));
      final destFile = File(localPath);
      
      final fileSize = await sourceFile.length();
      final reader = sourceFile.openRead();
      final writer = destFile.openWrite();
      
      int bytesWritten = 0;
      
      await for (final chunk in reader) {
        writer.add(chunk);
        bytesWritten += chunk.length;
        
        if (fileSize > 0) {
          controller.add(bytesWritten / fileSize);
        }
      }
      
      await writer.flush();
      await writer.close();
      
      controller.add(1.0);
      await controller.close();
    } catch (e) {
      controller.addError(e);
    }
    
    return controller.stream;
  }

  @override
  Future<FileItem> getFileDetails(String path) async {
    final absolutePath = _getAbsolutePath(path);
    final file = File(absolutePath);
    final directory = Directory(absolutePath);
    
    final isDirectory = await directory.exists();
    final fileSystemEntity = isDirectory ? directory : file;
    
    final stat = await fileSystemEntity.stat();
    final name = filepath.basename(absolutePath);
    
    return FileItem(
      id: path,
      name: name,
      path: path,
      type: isDirectory 
          ? FileType.folder 
          : FileItem.getFileTypeFromExtension(absolutePath),
      source: FileSource.local,
      isDirectory: isDirectory,
      modifiedDate: stat.modified,
      size: isDirectory ? null : stat.size,
      mimeType: null,
    );
  }

  @override
  Future<Map<String, String>> getFileProperties(String path) async {
    try {
      final absolutePath = _getAbsolutePath(path);
      final file = File(absolutePath);
      final directory = Directory(absolutePath);
      
      final isDirectory = await directory.exists();
      final fileSystemEntity = isDirectory ? directory : file;
      
      final stat = await fileSystemEntity.stat();
      
      return {
        'path': absolutePath,
        'isDirectory': isDirectory.toString(),
        'size': stat.size.toString(),
        'modified': stat.modified.toIso8601String(),
        'accessed': stat.accessed.toIso8601String(),
        'mode': stat.mode.toString(),
      };
    } catch (e) {
      return {};
    }
  }

  @override
  Future<int> getFreeSpace() async {
    // This is platform-specific and not directly supported by dart:io
    // Would require platform-specific code
    return -1;
  }

  @override
  Future<int> getTotalSpace() async {
    // This is platform-specific and not directly supported by dart:io
    return -1;
  }

  @override
  Future<List<FileItem>> listFiles(String directoryPath) async {
    try {
      final absolutePath = _getAbsolutePath(directoryPath);
      final directory = Directory(absolutePath);
      
      final entities = await directory.list().toList();
      final result = <FileItem>[];
      
      for (final entity in entities) {
        final relativePath = _getRelativePath(entity.path);
        final name = filepath.basename(entity.path);
        final isDirectory = entity is Directory;
        
        final stat = await entity.stat();
        
        result.add(FileItem(
          id: relativePath,
          name: name,
          path: relativePath,
          type: isDirectory 
              ? FileType.folder 
              : FileItem.getFileTypeFromExtension(entity.path),
          source: FileSource.local,
          isDirectory: isDirectory,
          modifiedDate: stat.modified,
          size: isDirectory ? null : stat.size,
          mimeType: null,
        ));
      }
      
      return result;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> lockFile(String path, {Duration? timeout}) async {
    // Not supported in the basic File API
    return false;
  }

  @override
  Future<bool> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(_getAbsolutePath(sourcePath));
      final destFile = File(_getAbsolutePath(destinationPath));
      
      await sourceFile.rename(destFile.path);
      return true;
    } catch (e) {
      try {
        // If rename fails (e.g., across volumes), try copy and delete
        await copyFile(sourcePath, destinationPath);
        await deleteFile(sourcePath);
        return true;
      } catch (e) {
        return false;
      }
    }
  }

  @override
  Future<Uint8List> readFile(String path) async {
    try {
      final file = File(_getAbsolutePath(path));
      return await file.readAsBytes();
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  @override
  Future<bool> renameFile(String path, String newName) async {
    try {
      final absolutePath = _getAbsolutePath(path);
      final directory = filepath.dirname(absolutePath);
      final newPath = filepath.join(directory, newName);
      
      final oldFile = File(absolutePath);
      await oldFile.rename(newPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<FileItem>> searchFiles(String query, {String? path}) async {
    final searchPath = path ?? '/';
    final allFiles = <FileItem>[];
    
    try {
      await _searchRecursive(_getAbsolutePath(searchPath), query.toLowerCase(), allFiles);
      return allFiles;
    } catch (e) {
      return [];
    }
  }

  Future<void> _searchRecursive(String currentPath, String query, List<FileItem> results) async {
    try {
      final directory = Directory(currentPath);
      final entities = await directory.list().toList();
      
      for (final entity in entities) {
        final name = filepath.basename(entity.path);
        final relativePath = _getRelativePath(entity.path);
        final isDirectory = entity is Directory;
        
        if (name.toLowerCase().contains(query)) {
          final stat = await entity.stat();
          
          results.add(FileItem(
            id: relativePath,
            name: name,
            path: relativePath,
            type: isDirectory 
                ? FileType.folder 
                : FileItem.getFileTypeFromExtension(entity.path),
            source: FileSource.local,
            isDirectory: isDirectory,
            modifiedDate: stat.modified,
            size: isDirectory ? null : stat.size,
            mimeType: null,
          ));
        }
        
        if (isDirectory && !name.startsWith('.')) {
          await _searchRecursive(entity.path, query, results);
        }
      }
    } catch (e) {
      // Skip this directory if there's an error
    }
  }

  @override
  Future<bool> setFileProperties(String path, Map<String, String> properties) async {
    // Not supported in the basic File API
    return false;
  }

  @override
  Future<bool> unlockFile(String path) async {
    // Not supported in the basic File API
    return false;
  }

  @override
  Future<Stream<double>> uploadFile(String localPath, String remotePath) async {
    final controller = BehaviorSubject<double>();
    
    try {
      final sourceFile = File(localPath);
      final destFile = File(_getAbsolutePath(remotePath));
      
      final fileSize = await sourceFile.length();
      final reader = sourceFile.openRead();
      final writer = destFile.openWrite();
      
      int bytesWritten = 0;
      
      await for (final chunk in reader) {
        writer.add(chunk);
        bytesWritten += chunk.length;
        
        if (fileSize > 0) {
          controller.add(bytesWritten / fileSize);
        }
      }
      
      await writer.flush();
      await writer.close();
      
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
      final file = File(_getAbsolutePath(path));
      await file.writeAsBytes(data);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> cancelTransfer(String path) async {
    // Not directly supported in the File API
    return false;
  }
  
  @override
  Future<bool> initializeConnection() {
    // TODO: implement initializeConnection
    throw UnimplementedError();
  }
}
