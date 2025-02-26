import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class PdfPreview extends StatefulWidget {
  final Uint8List fileData;

  const PdfPreview({
    super.key,
    required this.fileData,
  });

  @override
  State<PdfPreview> createState() => _PdfPreviewState();
}

class _PdfPreviewState extends State<PdfPreview> {
  late Future<String> _pdfPathFuture;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isReady = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _pdfPathFuture = _initPdf();
  }

  Future<String> _initPdf() async {
    try {
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/pdf_preview.pdf');
      await tempFile.writeAsBytes(widget.fileData);
      return tempFile.path;
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: FutureBuilder<String>(
            future: _pdfPathFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError || _errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Failed to load PDF: ${snapshot.error ?? _errorMessage}'),
                    ],
                  ),
                );
              }

              final path = snapshot.data!;
              if (path.isEmpty) {
                return const Center(child: Text('PDF could not be loaded'));
              }

              return Stack(
                children: [
                  PDFView(
                    filePath: path,
                    enableSwipe: true,
                    swipeHorizontal: true,
                    autoSpacing: false,
                    pageFling: true,
                    pageSnap: true,
                    defaultPage: _currentPage,
                    fitPolicy: FitPolicy.BOTH,
                    preventLinkNavigation: false,
                    onRender: (pages) {
                      setState(() {
                        _totalPages = pages!;
                        _isReady = true;
                        _isLoading = false;
                      });
                    },
                    onError: (error) {
                      setState(() {
                        _errorMessage = error.toString();
                        _isLoading = false;
                      });
                    },
                    onPageError: (page, error) {
                      setState(() {
                        _errorMessage = 'Error on page $page: $error';
                        _isLoading = false;
                      });
                    },
                    onViewCreated: (controller) {
                      // PDF view created
                    },
                    onPageChanged: (page, total) {
                      setState(() {
                        _currentPage = page!;
                      });
                    },
                  ),
                  if (_isLoading)
                    const Center(child: CircularProgressIndicator()),
                ],
              );
            },
          ),
        ),
        if (_isReady)
          Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.navigate_before),
                  onPressed: _currentPage > 0
                      ? () {
                          // Navigation handled by PDFView's swipe
                        }
                      : null,
                ),
                Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                IconButton(
                  icon: const Icon(Icons.navigate_next),
                  onPressed: _currentPage < _totalPages - 1
                      ? () {
                          // Navigation handled by PDFView's swipe
                        }
                      : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
