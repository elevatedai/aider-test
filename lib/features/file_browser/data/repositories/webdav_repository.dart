import 'dart:io';
import 'dart:typed_data';

import 'package:file_browser/features/file_browser/data/models/file_item.dart';
import 'package:file_browser/features/file_browser/domain/repositories/file_repository.dart';
import 'package:path/path.dart' as path;
import 'package:rxdart/rxdart.dart';
import 'package:webdav_client/webdav_client.dart' as webdav;

class WebDavRepository implements FileRepository {
  final String baseUrl;
  final String username;
  final String password;
  late final webdav.Client _client;
  bool _isConnected = false;

  WebDavRepository({
    required this.baseUrl,
    required this.username,
    required this.password,
  }) {
    _client = webdav.newClient(
      baseUrl,
      user: username,
      password: password,
      debug: false,
    );
  }

  @override
  bool get isConnected => _isConnected;

  @override
  Future<bool> connect() async {
    try {
      await _client.ping();
      _isConnected = true;
      return true;
    } catch (e) {
      _isConnected = false;
      return false;
    }
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
  }

  @override
  Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      await _client.copy(
        sourcePath,
        destinationPath,
        true,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> createDirectory(String path) async {
    try {
      await _client.mkdir(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    try {
      await _client.removeAll(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteFile(String path) async {
    try {
      await _client.remove(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Stream<double>> downloadFile(String remotePath, String localPath) async {
    final controller = BehaviorSubject<double>();

    try {
      final file = File(localPath);
      final sink = file.openWrite();

      await _client.read2File(
        remotePath,
        sink,
        onProgress: (progress) {
          controller.add(progress);
        },
      );

      await sink.close();
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
      final fileInfo = await _client.stat(path);
      return _convertToFileItem(fileInfo, path);
    } catch (e) {
      throw Exception('Failed to get file details: $e');
    }
  }

  @override
  Future<Map<String, String>> getFileProperties(String path) async {
    try {
      final props = await _client.getProperties(path: path);
      final result = <String, String>{};

      props.forEach((key, value) {
        result[key] = value.toString();
      });

      return result;
    } catch (e) {
      return {};
    }
  }

  @override
  Future<int> getFreeSpace() async {
    // The webdav_client library does not expose free space
    return -1;
  }

  @override
  Future<int> getTotalSpace() async {
    // The webdav_client library does not expose total space.
    return -1;
  }

  @override
  Future<List<FileItem>> listFiles(String directoryPath) async {
    try {
      final files = await _client.readDir(directoryPath);
      return files.map((file) => _convertToFileItem(file, file.path!)).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<bool> lockFile(String path, {Duration? timeout}) async {
    // The webdav_client library does not expose lock
    return false;
  }

  @override
  Future<bool> moveFile(String sourcePath, String destinationPath) async {
    try {
      await _client.move(
        src: sourcePath,
        dst: destinationPath,
        overwrite: true,
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<Uint8List> readFile(String path) async {
    try {
      return await _client.read(path);
    } catch (e) {
      throw Exception('Failed to read file: $e');
    }
  }

  @override
  Future<bool> renameFile(String path, String newName) async {
    try {
      final dirPath = path.substring(0, path.lastIndexOf('/'));
      final newPath = '$dirPath/$newName';
      await _client.move(src: path, dst: newPath, overwrite: true);
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
      await _searchRecursive(searchPath, query.toLowerCase(), allFiles);
      return allFiles;
    } catch (e) {
      return [];
    }
  }

  Future<void> _searchRecursive(String currentPath, String query, List<FileItem> results) async {
    try {
      final files = await _client.ls(currentPath);

      for (final file in files) {
        final fileItem = _convertToFileItem(file, file.path);

        if (fileItem.name.toLowerCase().contains(query)) {
          results.add(fileItem);
        }

        if (fileItem.isDirectory) {
          await _searchRecursive(fileItem.path, query, results);
        }
      }
    } catch (e) {
      // Skip this directory if there's an error
    }
  }

  @override
  Future<bool> setFileProperties(String path, Map<String, String> properties) async {
    // The webdav_client library does not expose set file properties
    return false;
  }

  @override
  Future<bool> unlockFile(String path) async {
    // The webdav_client library does not expose unlock file
    return false;
  }

  @override
  Future<Stream<double>> uploadFile(String localPath, String remotePath) async {
    final controller = BehaviorSubject<double>();

    try {
      final file = File(localPath);
      final stream = file.openRead();

      await _client.upload(
        remotePath,
        stream,
        onProgress: (progress) {
          controller.add(progress);
        },
      );

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
      await _client.write(path,data);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> cancelTransfer(String path) async {
    // WebDAV client doesn't directly support cancelling transfers
    return false;
  }

  FileItem _convertToFileItem(webdav.File file, String filePath) {
    final name = path.basename(filePath);
  

    final FileType type = file.isDir ==true ? FileType.folder : FileItem.getFileTypeFromExtension(filePath);

    return FileItem(
      id: filePath,
      name: name,
      path: filePath,
      type: type,
      source: FileSource.webdav,
      isDirectory: file.isDir ==true,
      modifiedDate: file.mTime,
      size: file.size,
      mimeType: file.mimeType,
    );
  }

  @override
  Future<bool> initializeConnection() async{
    try {
      await _client.ping();
      return true;
    } catch (e) {
      return false;
    }
  }
}
