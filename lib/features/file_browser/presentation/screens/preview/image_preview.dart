import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'dart:typed_data';

class ImagePreview extends StatelessWidget {
  final Uint8List fileData;
  final String fileName;

  const ImagePreview({
    super.key,
    required this.fileData,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: MemoryImage(fileData),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 2.0,
      backgroundDecoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
      ),
      loadingBuilder: (context, event) => Center(
        child: CircularProgressIndicator(
          value: event?.expectedTotalBytes != null
              ? (event!.cumulativeBytesLoaded / event.expectedTotalBytes!)
              : null,
        ),
      ),
      errorBuilder: (context, error, stackTrace) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.broken_image, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Failed to load image: $error'),
          ],
        ),
      ),
    );
  }
}
