import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf_viewer/screens/pdf_viewer_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // funtion to pick the file from the device storage
  Future<void> pickFile(BuildContext context) async {
    PlatformFile? file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (file != null) {
      if (file.path != null && file.path!.isNotEmpty) {
        if (!context.mounted) return;
        // Navigate to the PDF viewer screen with the selected file path
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerScreen(filePath: file.path!),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () => pickFile(context),
        foregroundColor: Colors.white,
        backgroundColor: Colors.red,
        child: const Icon(Icons.upload),
      ),
    );
  }
}
