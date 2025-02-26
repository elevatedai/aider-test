import 'package:file_browser/features/file_browser/presentation/providers/file_browser_provider.dart';
import 'package:file_browser/features/file_browser/presentation/widgets/file_grid_view.dart';
import 'package:file_browser/features/file_browser/presentation/widgets/file_list_view.dart';
import 'package:file_browser/features/settings/presentation/providers/settings_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class FileBrowserScreen extends ConsumerWidget {
  const FileBrowserScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = ref.watch(currentPathProvider);
    final filesAsync = ref.watch(filesProvider(currentPath));
    final viewMode = ref.watch(settingsProvider.select((s) => s.viewMode));
    final appBarTitle = _getAppBarTitle(currentPath);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              context.go('/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () {
              _showViewOptions(context, ref);
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              _showSortOptions(context, ref);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStorageInfoCard(context),
          _buildBreadcrumbs(context, ref, currentPath),
          Expanded(
            child: filesAsync.when(
              data: (files) {
                if (files.isEmpty) {
                  return Center(
                    child: Text('This folder is empty', style: theme.textTheme.bodyLarge),
                  );
                }

                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: viewMode == ViewMode.grid
                      ? FileGridView(files: files)
                      : FileListView(files: files),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Error loading files: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStorageInfoCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Storage Info', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total Space:'),
                Text('128 GB', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Used Space:'),
                Text('64 GB', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Free Space:'),
                Text('64 GB', style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbs(BuildContext context, WidgetRef ref, String path) {
    final pathParts = path.split('/').where((part) => part.isNotEmpty).toList();
    final items = <Widget>[];
    final ScrollController scrollController = ScrollController();

    items.add(
      InkWell(
        onTap: () {
          ref.read(currentPathProvider.notifier).state = '/';
          //Scroll to start when enter new directory
          scrollController.animateTo(
            0.0,
            curve: Curves.easeOut,
            duration: const Duration(milliseconds: 200),
          );
        },
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: Text('Home', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      )
    );

    String currentPath = '';
    for (int i = 0; i < pathParts.length; i++) {
      final part = pathParts[i];
      currentPath += '/$part';
      
      items.add(const Text(' / '));
      items.add(
        InkWell(
          onTap: () {
            ref.read(currentPathProvider.notifier).state = currentPath;
             //Scroll to start when enter new directory
            scrollController.animateTo(
              0.0,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 200),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Text(part, 
              style: i == pathParts.length - 1 
                ? const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                : const TextStyle(fontSize: 16)
            ),
          ),
        )
      );
    }

    return Container(
      height: 48,
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        child: Row(children: items),
      ),
    );
  }

  void _showViewOptions(BuildContext context, WidgetRef ref) {
    final currentViewMode = ref.read(settingsProvider).viewMode;
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.grid_view),
                title: const Text('Grid View'),
                selected: currentViewMode == ViewMode.grid,
                onTap: () {
                  ref.read(settingsProvider.notifier).setViewMode(ViewMode.grid);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.view_list),
                title: const Text('List View'),
                selected: currentViewMode == ViewMode.list,
                onTap: () {
                  ref.read(settingsProvider.notifier).setViewMode(ViewMode.list);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.details),
                title: const Text('Details View'),
                selected: currentViewMode == ViewMode.details,
                onTap: () {
                  ref.read(settingsProvider.notifier).setViewMode(ViewMode.details);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSortOptions(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Name'),
                selected: settings.sortBy == SortBy.name,
                onTap: () {
                  ref.read(settingsProvider.notifier).setSortBy(SortBy.name);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Date Modified'),
                selected: settings.sortBy == SortBy.date,
                onTap: () {
                  ref.read(settingsProvider.notifier).setSortBy(SortBy.date);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.data_usage),
                title: const Text('Size'),
                selected: settings.sortBy == SortBy.size,
                onTap: () {
                  ref.read(settingsProvider.notifier).setSortBy(SortBy.size);
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Type'),
                selected: settings.sortBy == SortBy.type,
                onTap: () {
                  ref.read(settingsProvider.notifier).setSortBy(SortBy.type);
                  Navigator.pop(context);
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(
                  settings.sortAscending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                title: Text(
                  settings.sortAscending ? 'Ascending' : 'Descending',
                ),
                onTap: () {
                  ref.read(settingsProvider.notifier).toggleSortDirection();
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.create_new_folder),
                title: const Text('New Folder'),
                onTap: () {
                  Navigator.pop(context);
                  _showNewFolderDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.upload_file),
                title: const Text('Upload File'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadFile(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.text_snippet),
                title: const Text('New Text File'),
                onTap: () {
                  Navigator.pop(context);
                  _showNewTextFileDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Implement photo capture
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNewFolderDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Folder'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Folder Name',
              hintText: 'Enter folder name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                final folderName = textController.text.trim();
                if (folderName.isNotEmpty) {
                  ref.read(fileBrowserProvider.notifier)
                    .createDirectory(folderName);
                }
                Navigator.pop(context);
              },
              child: const Text('CREATE'),
            ),
          ],
        );
      },
    );
  }
  
  void _showNewTextFileDialog(BuildContext context, WidgetRef ref) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New Text File'),
          content: TextField(
            controller: textController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'File Name',
              hintText: 'Enter file name (e.g. notes.txt)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () {
                final fileName = textController.text.trim();
                if (fileName.isNotEmpty) {
                  // TODO: Implement create text file
                  // For now just show a message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Creating $fileName')),
                  );
                }
                Navigator.pop(context);
              },
              child: const Text('CREATE'),
            ),
          ],
        );
      },
    );
  }

  void _uploadFile(BuildContext context, WidgetRef ref) {
    // TODO: Implement file picking and upload
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload feature coming soon')),
    );
  }

  String _getAppBarTitle(String path) {
    if (path == '/') {
      return 'Files';
    }
    
    final parts = path.split('/');
    return parts.last;
  }
}
