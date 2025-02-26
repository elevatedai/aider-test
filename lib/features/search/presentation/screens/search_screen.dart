import 'package:file_browser/features/file_browser/data/models/file_item.dart';
import 'package:file_browser/features/file_browser/presentation/screens/preview/file_preview_screen.dart';
import 'package:file_browser/features/search/presentation/providers/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final dateFormat = DateFormat('MMM d, yyyy');

  @override
  void initState() {
    super.initState();
    // Request focus on the search field when the screen is opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final isSearching = ref.watch(isSearchingProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: 'Search files',
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                ref.read(searchResultsProvider.notifier).clearResults();
              },
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              ref.read(searchResultsProvider.notifier).search(value);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: isSearching ? const LinearProgressIndicator() : Container(),
        ),
      ),
      body: Column(
        children: [
          _buildSearchFilters(),
          Expanded(
            child: searchResults.when(
              data: (files) {
                if (files.isEmpty) {
                  return _buildEmptyState();
                }
                
                return ListView.builder(
                  itemCount: files.length,
                  itemBuilder: (context, index) {
                    final file = files[index];
                    return _buildSearchResultItem(file);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_searchController.text.isNotEmpty) {
            ref.read(searchResultsProvider.notifier).search(_searchController.text);
          }
        },
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildSearchFilters() {
    final searchFilter = ref.watch(searchFilterProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Text('Search in: '),
          const SizedBox(width: 8),
          DropdownButton<SearchFilter>(
            value: searchFilter,
            items: const [
              DropdownMenuItem(
                value: SearchFilter.name,
                child: Text('Name'),
              ),
              DropdownMenuItem(
                value: SearchFilter.content,
                child: Text('Content'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                ref.read(searchFilterProvider.notifier).state = value;
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No search results',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultItem(FileItem file) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(_getFileIcon(file)),
        title: Text(file.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modified: ${dateFormat.format(file.modifiedDate!)}'),
            Text('Path: ${file.path}'),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FilePreviewScreen(file: file),
            ),
          );
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
}
