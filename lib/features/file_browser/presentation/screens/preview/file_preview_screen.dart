import 'dart:typed_data';

import 'package:file_browser/features/file_browser/data/models/file_item.dart';
import 'package:file_browser/features/file_browser/presentation/providers/file_browser_provider.dart';
import 'package:file_browser/features/file_browser/presentation/screens/preview/image_preview.dart';
import 'package:file_browser/features/file_browser/presentation/screens/preview/pdf_preview.dart';
import 'package:file_browser/features/file_browser/presentation/screens/preview/text_preview.dart';
import 'package:file_browser/features/file_browser/presentation/screens/preview/video_preview.dart';
import 'package:file_browser/features/file_browser/presentation/screens/preview/audio_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class FilePreviewScreen extends ConsumerStatefulWidget {
  final FileItem file;

  const FilePreviewScreen({
    super.key,
    required this.file,
  });

  @override
  ConsumerState<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends ConsumerState<FilePreviewScreen> {
  late Future<Uint8List> _fileDataFuture;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _fileDataFuture = _loadFileData();
  }

  Future<Uint8List> _loadFileData() async {
    final repository = ref.read(fileRepositoryProvider);
    return await repository.readFile(widget.file.path);
  }

  Future<void> _shareFile() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${widget.file.name}');
      
      final fileData = await _fileDataFuture;
      await tempFile.writeAsBytes(fileData);
      
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: 'Sharing ${widget.file.name}',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _downloadFile() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      final fileData = await _fileDataFuture;
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${widget.file.name}';
      final file = File(filePath);
      await file.writeAsBytes(fileData);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded to ${file.path}'),
            action: SnackBarAction(
              label: 'OPEN',
              onPressed: () => OpenFile.open(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download file: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.file.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _isDownloading ? null : _shareFile,
            tooltip: 'Share',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _isDownloading ? null : _downloadFile,
            tooltip: 'Download',
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: _fileDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading file: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _fileDataFuture = _loadFileData();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final fileData = snapshot.data!;
          
          // Choose the appropriate preview widget based on file type
          switch (widget.file.type) {
            case FileType.image:
              return ImagePreview(fileData: fileData, fileName: widget.file.name);
            case FileType.video:
              return VideoPreview(fileData: fileData, fileName: widget.file.name);
            case FileType.audio:
              return AudioPreview(fileData: fileData, fileName: widget.file.name);
            case FileType.pdf:
              return PdfPreview(fileData: fileData);
            case FileType.text:
              return TextPreview(fileData: fileData);
            default:
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getFileIcon(widget.file),
                      size: 100,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${widget.file.name}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'File size: ${_formatFileSize(widget.file.size ?? 0)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _downloadFile,
                      child: const Text('Download and Open'),
                    ),
                  ],
                ),
              );
          }
        },
      ),
    );
  }

  IconData _getFileIcon(FileItem file) {
    switch (file.type) {
      case FileType.image:
        return Icons.image;
      case FileType.video:
        return Icons.video_file;
      case FileType.audio:
        return Icons.audio_file;
      case FileType.pdf:
        return Icons.picture_as_pdf;
      case FileType.text:
        return Icons.description;
      case FileType.archive:
        return Icons.archive;
      case FileType.folder:
        return Icons.folder;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var i = 0;
    double size = bytes.toDouble();
    
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    
    return '${size.toStringAsFixed(1)} ${suffixes[i]}';
  }
}
