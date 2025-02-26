import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:convert';

class TextPreview extends StatelessWidget {
  final Uint8List fileData;

  const TextPreview({
    super.key,
    required this.fileData,
  });

  @override
  Widget build(BuildContext context) {
    String? textContent;
    String? errorMessage;

    try {
      textContent = utf8.decode(fileData);
    } catch (e) {
      errorMessage = 'Could not decode file. It might not be a text file or uses unsupported encoding.';
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(errorMessage),
          ],
        ),
      );
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SelectableText(
          textContent!,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
