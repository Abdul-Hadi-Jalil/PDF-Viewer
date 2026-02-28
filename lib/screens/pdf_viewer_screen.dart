import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

// Separate PDF viewer screen
class PDFViewerScreen extends StatelessWidget {
  final String filePath;
  final String fileName;

  const PDFViewerScreen({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(fileName), backgroundColor: Colors.black54),
      body: PDFView(filePath: filePath, autoSpacing: false, pageFling: false),
    );
  }
}
