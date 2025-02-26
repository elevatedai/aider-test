import 'dart:typed_data';

import 'package:file_browser/features/file_browser/data/models/file_item.dart';
import 'package:file_browser/features/file_browser/domain/repositories/file_repository.dart';
import 'package:file_browser/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final currentPathProvider = StateProvider<String>((ref) => '/');

final fileRepositoryProvider = Provider<FileRepository>((ref) {
  // Return a mock implementation for now
  return MockFileRepository();
});

final filesProvider = FutureProvider.family<List<FileItem>, String>((ref, path) async {
  final repository = ref.watch(fileRepositoryProvider);
  final settings = ref.watch(settingsProvider);
  
  final files = await repository.listFiles(path);
  
  // Filter hidden files if necessary
  final filteredFiles = settings.showHiddenFiles 
      ? files 
      : files.where((file) => !file.name.startsWith('.')).toList();
  
  // Sort the files according to settings
  filteredFiles.sort((a, b) {
    // Always put directories first
    if (a.isDirectory && !b.isDirectory) return -1;
    if (!a.isDirectory && b.isDirectory) return 1;
    
    // Then sort according to settings
    switch (settings.sortBy) {
      case SortBy.name:
        return settings.sortAscending 
            ? a.name.compareTo(b.name) 
            : b.name.compareTo(a.name);
      case SortBy.date:
        if (a.modifiedDate == null) return settings.sortAscending ? -1 : 1;
        if (b.modifiedDate == null) return settings.sortAscending ? 1 : -1;
        return settings.sortAscending 
            ? a.modifiedDate!.compareTo(b.modifiedDate!) 
            : b.modifiedDate!.compareTo(a.modifiedDate!);
      case SortBy.size:
        final aSize = a.size ?? 0;
        final bSize = b.size ?? 0;
        return settings.sortAscending ? aSize.compareTo(bSize) : bSize.compareTo(aSize);
      case SortBy.type:
        if (a.type == b.type) {
          return settings.sortAscending ? a.name.compareTo(b.name) : b.name.compareTo(a.name);
        }
        return settings.sortAscending 
            ? a.type.index.compareTo(b.type.index) 
            : b.type.index.compareTo(a.type.index);
    }
  });
  
  return filteredFiles;
});

final fileBrowserProvider = StateNotifierProvider<FileBrowserNotifier, AsyncValue<void>>((ref) {
  final repository = ref.watch(fileRepositoryProvider);
  return FileBrowserNotifier(repository, ref);
});

class FileBrowserNotifier extends StateNotifier<AsyncValue<void>> {
  final FileRepository _repository;
  final Ref _ref;
  
  FileBrowserNotifier(this._repository, this._ref) : super(const AsyncValue.data(null));
  
  Future<void> createDirectory(String name) async {
    state = const AsyncValue.loading();
    try {
      final currentPath = _ref.read(currentPathProvider);
      final path = '$currentPath${currentPath.endsWith('/') ? '' : '/'}$name';
      
      final result = await _repository.createDirectory(path);
      
      if (result) {
        state = const AsyncValue.data(null);
        // Refresh file list
        _ref.refresh(filesProvider(_ref.read(currentPathProvider)));
      } else {
        state = AsyncValue.error('Failed to create directory', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> deleteFile(FileItem file) async {
    state = const AsyncValue.loading();
    try {
      final result = file.isDirectory 
          ? await _repository.deleteDirectory(file.path) 
          : await _repository.deleteFile(file.path);
      
      if (result) {
        state = const AsyncValue.data(null);
        // Refresh file list
        _ref.refresh(filesProvider(_ref.read(currentPathProvider)));
      } else {
        state = AsyncValue.error('Failed to delete ${file.isDirectory ? 'directory' : 'file'}', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
  
  Future<void> renameFile(FileItem file, String newName) async {
    state = const AsyncValue.loading();
    try {
      // Extract parent directory from path
      final pathParts = file.path.split('/')..removeLast();
      final parentPath = pathParts.join('/');
      final newPath = '$parentPath/${newName}';
      
      final result = await _repository.renameFile(file.path, newName);
      
      if (result) {
        state = const AsyncValue.data(null);
        // Refresh file list
        _ref.refresh(filesProvider(_ref.read(currentPathProvider)));
      } else {
        state = AsyncValue.error('Failed to rename file', StackTrace.current);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Mock implementation for development
class MockFileRepository implements FileRepository {
  final _files = <String, List<FileItem>>{
    '/': [
      FileItem(
        id: '1',
        name: 'Documents',
        path: '/Documents',
        type: FileType.folder,
        source: FileSource.local,
        isDirectory: true,
        modifiedDate: DateTime.now(),
      ),
      FileItem(
        id: '2',
        name: 'Pictures',
        path: '/Pictures',
        type: FileType.folder,
        source: FileSource.local,
        isDirectory: true,
        modifiedDate: DateTime.now().subtract(const Duration(days: 1)),
      ),
      FileItem(
        id: '3',
        name: 'Videos',
        path: '/Videos',
        type: FileType.folder,
        source: FileSource.local,
        isDirectory: true,
        modifiedDate: DateTime.now().subtract(const Duration(days: 2)),
      ),
      FileItem(
        id: '4',
        name: 'Music',
        path: '/Music',
        type: FileType.folder,
        source: FileSource.local,
        isDirectory: true,
        modifiedDate: DateTime.now().subtract(const Duration(days: 3)),
      ),
      FileItem(
        id: '5',
        name: 'notes.txt',
        path: '/notes.txt',
        type: FileType.text,
        source: FileSource.local,
        isDirectory: false,
        modifiedDate: DateTime.now(),
        size: 1024,
        mimeType: 'text/plain',
      ),
      FileItem(
        id: '6',
        name: 'image.jpg',
        path: '/image.jpg',
        type: FileType.image,
        source: FileSource.local,
        isDirectory: false,
        modifiedDate: DateTime.now().subtract(const Duration(hours: 5)),
        size: 1024 * 1024 * 2,
        mimeType: 'image/jpeg',
      ),
    ],
    '/Documents': [
      FileItem(
        id: '7',
        name: 'Work',
        path: '/Documents/Work',
        type: FileType.folder,
        source: FileSource.local,
        isDirectory: true,
        modifiedDate: DateTime.now(),
      ),
      FileItem(
        id: '8',
        name: 'Personal',
        path: '/Documents/Personal',
        type: FileType.folder,
        source: FileSource.local,
        isDirectory: true,
        modifiedDate: DateTime.now(),
      ),
      FileItem(
        id: '9',
        name: 'report.pdf',
        path: '/Documents/report.pdf',
        type: FileType.pdf,
        source: FileSource.local,
        isDirectory: false,
        modifiedDate: DateTime.now(),
        size: 1024 * 1024 * 3,
        mimeType: 'application/pdf',
      ),
    ],
  };

  @override
  bool get isConnected => true;

  @override
  Future<bool> connect() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return true;
  }

  @override
  Future<bool> copyFile(String sourcePath, String destinationPath) {
    throw UnimplementedError();
  }

  @override
  Future<bool> createDirectory(String path) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get parent directory path
    final parts = path.split('/')..removeLast();
    final parentPath = parts.isEmpty ? '/' : parts.join('/');
    
    // Get directory name
    final name = path.split('/').last;
    
    // Create new file item
    final newDir = FileItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      path: path,
      type: FileType.folder,
      source: FileSource.local,
      isDirectory: true,
      modifiedDate: DateTime.now(),
    );
    
    // Add to parent directory
    if (_files.containsKey(parentPath)) {
      _files[parentPath]!.add(newDir);
    } else {
      _files[parentPath] = [newDir];
    }
    
    // Create empty directory
    _files[path] = [];
    
    return true;
  }

  @override
  Future<bool> deleteDirectory(String path) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get parent directory path
    final parts = path.split('/')..removeLast();
    final parentPath = parts.isEmpty ? '/' : parts.join('/');
    
    // Remove directory from parent
    if (_files.containsKey(parentPath)) {
      _files[parentPath]!.removeWhere((item) => item.path == path);
    }
    
    // Remove directory and its contents
    _files.remove(path);
    
    return true;
  }

  @override
  Future<bool> deleteFile(String path) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get parent directory path
    final parts = path.split('/')..removeLast();
    final parentPath = parts.isEmpty ? '/' : parts.join('/');
    
    // Remove file from parent
    if (_files.containsKey(parentPath)) {
      _files[parentPath]!.removeWhere((item) => item.path == path);
    }
    
    return true;
  }

  @override
  Future<void> disconnect() async {
    return;
  }

  @override
  Future<Stream<double>> downloadFile(String remotePath, String localPath) {
    throw UnimplementedError();
  }

  @override
  Future<FileItem> getFileDetails(String path) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, String>> getFileProperties(String path) {
    throw UnimplementedError();
  }

  @override
  Future<int> getFreeSpace() {
    throw UnimplementedError();
  }

  @override
  Future<int> getTotalSpace() {
    throw UnimplementedError();
  }

  @override
  Future<List<FileItem>> listFiles(String path) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _files[path] ?? [];
  }

  @override
  Future<bool> lockFile(String path, {Duration? timeout}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> moveFile(String sourcePath, String destinationPath) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> readFile(String path) {
    throw UnimplementedError();
  }

  @override
  Future<bool> renameFile(String path, String newName) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Get parent directory path
    final parts = path.split('/')..removeLast();
    final parentPath = parts.isEmpty ? '/' : parts.join('/');
    
    // Get new path
    final newPath = '$parentPath/$newName';
    
    // Update file in parent directory
    if (_files.containsKey(parentPath)) {
      final fileIndex = _files[parentPath]!.indexWhere((item) => item.path == path);
      if (fileIndex != -1) {
        final file = _files[parentPath]![fileIndex];
        _files[parentPath]![fileIndex] = FileItem(
          id: file.id,
          name: newName,
          path: newPath,
          type: file.type,
          source: file.source,
          isDirectory: file.isDirectory,
          modifiedDate: DateTime.now(),
          size: file.size,
          mimeType: file.mimeType,
          metadata: file.metadata,
        );
        
        // If it's a directory, update its path key in _files map
        if (file.isDirectory) {
          final contents = _files[path] ?? [];
          _files.remove(path);
          _files[newPath] = contents;
        }
      }
    }
    
    return true;
  }

  @override
  Future<List<FileItem>> searchFiles(String query, {String? path}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> setFileProperties(String path, Map<String, String> properties) {
    throw UnimplementedError();
  }

  @override
  Future<bool> unlockFile(String path) {
    throw UnimplementedError();
  }

  @override
  Future<Stream<double>> uploadFile(String localPath, String remotePath) {
    throw UnimplementedError();
  }

  @override
  Future<bool> writeFile(String path, Uint8List data) {
    throw UnimplementedError();
  }

  @override
  Future<bool> cancelTransfer(String path) {
    throw UnimplementedError();
  }
  
  @override
  Future<bool> initializeConnection() {
    // TODO: implement initializeConnection
    throw UnimplementedError();
  }
}
