import 'package:file_browser/features/file_browser/data/models/file_item.dart';

class SelectableFileItem {
  final FileItem file;
  bool isSelected;

  SelectableFileItem({
    required this.file,
    this.isSelected = false,
  });

  SelectableFileItem copyWith({
    FileItem? file,
    bool? isSelected,
  }) {
    return SelectableFileItem(
      file: file ?? this.file,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}
