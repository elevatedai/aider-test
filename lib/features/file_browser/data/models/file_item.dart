import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flutter/foundation.dart';

part 'file_item.freezed.dart';
part 'file_item.g.dart';

enum FileSource {
  local,
  webdav,
  ftp,
  ftps,
}

enum FileType {
  folder,
  image,
  video,
  audio,
  pdf,
  text,
  archive,
  other,
}

@freezed
class FileItem with _$FileItem {
  const factory FileItem({
    required String id,
    required String name,
    required String path,
    required FileType type,
    required FileSource source,
    required bool isDirectory,
    required DateTime? modifiedDate,
    int? size,
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) = _FileItem;

  factory FileItem.fromJson(Map<String, dynamic> json) => 
      _$FileItemFromJson(json);
      
  static FileType getFileTypeFromExtension(String path) {
    final ext = path.split('.').last.toLowerCase();
    
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'heic'].contains(ext)) {
      return FileType.image;
    } else if (['mp4', 'mov', 'avi', 'mkv', 'webm'].contains(ext)) {
      return FileType.video;
    } else if (['mp3', 'wav', 'ogg', 'aac', 'flac'].contains(ext)) {
      return FileType.audio;
    } else if (ext == 'pdf') {
      return FileType.pdf;
    } else if (['txt', 'md', 'json', 'xml', 'html', 'css', 'js', 'dart'].contains(ext)) {
      return FileType.text;
    } else if (['zip', 'rar', '7z', 'tar', 'gz'].contains(ext)) {
      return FileType.archive;
    } else {
      return FileType.other;
    }
  }
}
