import 'package:file_browser/features/file_browser/data/models/file_item.dart';
import 'package:file_browser/features/file_browser/data/models/selectable_file_item.dart';
import 'package:file_browser/features/file_browser/presentation/providers/file_browser_provider.dart';
import 'package:file_browser/features/file_browser/presentation/screens/preview/file_preview_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FileGridView extends ConsumerStatefulWidget {
  final List<FileItem> files;

  const FileGridView({super.key, required this.files});

  @override
  ConsumerState<FileGridView> createState() => _FileGridViewState();
}

class _FileGridViewState extends ConsumerState<FileGridView> {
  bool _multiSelectMode = false;
  List<SelectableFileItem> _selectableFiles = [];

  @override
  void initState() {
    super.initState();
    _selectableFiles = widget.files.map((file) => SelectableFileItem(file: file)).toList();
  }

  @override
  void didUpdateWidget(covariant FileGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.files != widget.files) {
      _selectableFiles = widget.files.map((file) => SelectableFileItem(file: file)).toList();
    }
  }

  void _toggleMultiSelectMode() {
    setState(() {
      _multiSelectMode = !_multiSelectMode;
      if (!_multiSelectMode) {
        _clearSelection();
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      _selectableFiles[index].isSelected = !_selectableFiles[index].isSelected;
    });
  }

  void _clearSelection() {
    setState(() {
      for (var i = 0; i < _selectableFiles.length; i++) {
        _selectableFiles[i].isSelected = false;
      }
    });
  }

  List<FileItem> get _selectedFiles {
    return _selectableFiles.where((item) => item.isSelected).map((item) => item.file).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 3 / 4,
          crossAxisSpacing: 8.0,
          mainAxisSpacing: 8.0,
        ),
        itemCount: _selectableFiles.length,
        itemBuilder: (context, index) {
          final selectableFile = _selectableFiles[index];
          return _FileGridItem(
            file: selectableFile.file,
            isSelected: selectableFile.isSelected,
            multiSelectMode: _multiSelectMode,
            onTap: () {
              if (_multiSelectMode) {
                _toggleSelection(index);
              } else {
                _handleFileTap(context, selectableFile.file, ref);
              }
            },
            onLongPress: () {
              if (_multiSelectMode) {
                _toggleSelection(index);
              } else {
                _toggleMultiSelectMode();
                _toggleSelection(index);
              }
            },
          );
        },
      ),
      bottomNavigationBar: _multiSelectMode
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  IconButton(
                    icon: const Icon(Icons.copy),
                    onPressed: () {
                      // TODO: Implement copy functionality for selected files
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.cut),
                    onPressed: () {
                      // TODO: Implement move functionality for selected files
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _showDeleteConfirmation(context, _selectedFiles, ref);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      _toggleMultiSelectMode();
                    },
                  ),
                ],
              ),
            )
          : null,
    );
  }

  void _handleFileTap(BuildContext context, FileItem file, WidgetRef ref) {
    if (file.isDirectory) {
      ref.read(currentPathProvider.notifier).state = file.path;
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FilePreviewScreen(file: file),
        ),
      );
    }
  }

  void _showDeleteConfirmation(BuildContext context, List<FileItem> files, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete'),
          content: Text('Are you sure you want to delete ${files.length} item(s)?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                for (final file in files) {
                  ref.read(fileBrowserProvider.notifier).deleteFile(file);
                }
                Navigator.pop(context);
                _toggleMultiSelectMode();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );
  }
}

class _FileGridItem extends StatelessWidget {
  final FileItem file;
  final bool isSelected;
  final bool multiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _FileGridItem({
    required this.file,
    required this.isSelected,
    required this.multiSelectMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: file.isDirectory
                          ? theme.colorScheme.primary.withOpacity(0.1)
                          : theme.colorScheme.secondaryContainer,
                    ),
                    child: Center(
                      child: _getFileIcon(file, size: 48),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        file.name,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (!file.isDirectory && file.size != null)
                        Text(
                          _formatFileSize(file.size!),
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (multiSelectMode)
              Positioned(
                top: 4,
                right: 4,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _getFileIcon(FileItem file, {double size = 24}) {
    if (file.isDirectory) {
      return Icon(Icons.folder, size: size, color: Colors.amber[700]);
    }

    switch (file.type) {
      case FileType.image:
        return Icon(Icons.image, size: size, color: Colors.blue[700]);
      case FileType.video:
        return Icon(Icons.video_file, size: size, color: Colors.red[700]);
      case FileType.audio:
        return Icon(Icons.audio_file, size: size, color: Colors.purple[700]);
      case FileType.pdf:
        return Icon(Icons.picture_as_pdf, size: size, color: Colors.red[900]);
      case FileType.text:
        return Icon(Icons.description, size: size, color: Colors.blue[900]);
      case FileType.archive:
        return Icon(Icons.archive, size: size, color: Colors.brown[700]);
      case FileType.folder:
        return Icon(Icons.folder, size: size, color: Colors.amber[700]);
      default:
        return Icon(Icons.insert_drive_file, size: size, color: Colors.grey[700]);
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
