import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:pdf_viewer/screens/pdf_viewer_screen.dart';

class ViewPdfFromLocalStorage extends StatefulWidget {
  const ViewPdfFromLocalStorage({super.key});

  @override
  State<ViewPdfFromLocalStorage> createState() =>
      _ViewPdfFromLocalStorageState();
}

class _ViewPdfFromLocalStorageState extends State<ViewPdfFromLocalStorage> {
  // variable to store the picked file path
  String? filePath;
  String? fileName;

  // function to pick file from local storage
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      filePath = result.files.single.path;
      fileName = result.files.single.name;

      // Navigate to PDF viewer screen
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PDFViewerScreen(filePath: filePath!, fileName: fileName!),
          ),
        );
      }
    } else {
      // User canceled the picker
      debugPrint('No file selected');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View PDF from Local Storage'),
        backgroundColor: Colors.grey,
      ),
      floatingActionButton: FloatingActionButton(
        foregroundColor: Colors.white,
        backgroundColor: Colors.blue,
        onPressed: () {
          pickFile();
        },
        child: const Icon(Icons.upload_file_outlined),
      ),
    );
  }
}
