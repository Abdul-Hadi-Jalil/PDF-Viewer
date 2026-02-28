import 'package:flutter/material.dart';
import 'package:pdf_viewer/screens/pdf_view_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF Viewer')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PdfViewPage()),
              );
            },
            child: const Text('View PDF'),
          ),
        ],
      ),
    );
  }
}
