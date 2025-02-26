
enum FileSource {
  local,
  webdav,
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

class FileItem {
  final String id;
  final String name;
  final String path;
  final FileType type;
  final FileSource source;
  final bool isDirectory;
  final DateTime? modifiedDate;
  final int? size;
  final String? mimeType;
  final Map<String, dynamic>? metadata;

  const FileItem({
    required this.id,
    required this.name, 
    required this.path,
    required this.type,
    required this.source,
    required this.isDirectory,
    required this.modifiedDate,
    this.size,
    this.mimeType,
    this.metadata,
  });

  factory FileItem.fromJson(Map<String, dynamic> json) {
    return FileItem(
      id: json['id'] as String,
      name: json['name'] as String,
      path: json['path'] as String,
      type: FileType.values[json['type'] as int],
      source: FileSource.values[json['source'] as int],
      isDirectory: json['isDirectory'] as bool,
      modifiedDate: json['modifiedDate'] != null 
          ? DateTime.parse(json['modifiedDate'] as String)
          : null,
      size: json['size'] as int?,
      mimeType: json['mimeType'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'type': type.index,
      'source': source.index,
      'isDirectory': isDirectory,
      'modifiedDate': modifiedDate?.toIso8601String(),
      'size': size,
      'mimeType': mimeType,
      'metadata': metadata,
    };
  }

  FileItem copyWith({
    String? id,
    String? name,
    String? path,
    FileType? type,
    FileSource? source,
    bool? isDirectory,
    DateTime? modifiedDate,
    int? size,
    String? mimeType,
    Map<String, dynamic>? metadata,
  }) {
    return FileItem(
      id: id ?? this.id,
      name: name ?? this.name,
      path: path ?? this.path,
      type: type ?? this.type,
      source: source ?? this.source,
      isDirectory: isDirectory ?? this.isDirectory,
      modifiedDate: modifiedDate ?? this.modifiedDate,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
      metadata: metadata ?? this.metadata,
    );
  }
      
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
