import 'package:flutter/material.dart';
import 'package:pdf_viewer/widgets/fast_pdf_scroll_physics.dart';
import 'package:pdfrx/pdfrx.dart';

class PdfViewerScreen extends StatelessWidget {
  final String filePath;
  const PdfViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PdfViewer.file(
        filePath,
        params: const PdfViewerParams(
          scrollPhysics: FastPdfScrollPhysics(speedMultiplier: 2.0),
          // Keep pinch zoom independent of the scrolling boost.
          //scrollPhysicsScale: ClampingScrollPhysics(),
        ),
      ),
    );
  }
}
