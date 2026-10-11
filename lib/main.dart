import 'package:flutter/material.dart';
import 'package:pdf_viewer/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PDFViewer());
}

class PDFViewer extends StatelessWidget {
  const PDFViewer({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter PDF Viewer Application',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.red.shade400)),
      home: const HomeScreen(),
    );
  }
}
