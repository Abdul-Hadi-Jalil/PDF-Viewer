import 'package:flutter/material.dart';
//import 'package:pdf_viewer/screens/home_screen.dart';
import 'package:pdf_viewer/screens/select_pdf_from_local_storage.dart';
import 'package:pdf_viewer/screens/show_pdf_from_url.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'PDF Viewer', home: ShowPdfFromUrl());
  }
}
