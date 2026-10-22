import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:material_ui/material_ui.dart';

class PdfViewerScreen extends StatelessWidget {
  final String filePath;
  const PdfViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: PdfViewer.file(filePath));
  }
}
