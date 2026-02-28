import 'dart:async';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:pdf_viewer/screens/pdf_viewer_screen.dart';
import 'package:pdf_viewer/screens/view_pdf_from_local_storage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? initialFilePath;
  late StreamSubscription<List<SharedMediaFile>> _mediaStreamSubscription;

  @override
  void initState() {
    super.initState();
    _handleInitialMedia();
    _listenForIncomingMedia();
  }

  // Handle when app is opened from a file (app not running)
  Future<void> _handleInitialMedia() async {
    // For media files (PDFs, images, videos) - this is what we need for PDFs
    final sharedFiles = await ReceiveSharingIntent.instance.getInitialMedia();
    if (sharedFiles.isNotEmpty) {
      _handleIncomingFile(sharedFiles.first.path);
    }
  }

  // Listen for files shared while app is running
  void _listenForIncomingMedia() {
    // Listen for media file shares (PDFs come through this stream)
    _mediaStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> files) {
            if (files.isNotEmpty) {
              _handleIncomingFile(files.first.path);
            }
          },
          onError: (err) {
            debugPrint("Error in media stream: $err");
          },
        );
  }

  // Helper method to handle incoming files
  void _handleIncomingFile(String filePath) {
    // Extract filename from path
    String fileName = filePath.split('/').last;

    // Use post-frame callback to ensure navigation happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Clear the navigation stack and open the PDF
        Navigator.popUntil(context, (route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                PDFViewerScreen(filePath: filePath, fileName: fileName),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    // Cancel subscription
    _mediaStreamSubscription.cancel();

    // Reset the intent to prevent memory leaks
    ReceiveSharingIntent.instance.reset();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Viewer',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: initialFilePath != null
          ? PDFViewerScreen(
              filePath: initialFilePath!,
              fileName: initialFilePath!.split('/').last,
            )
          : const ViewPdfFromLocalStorage(),
    );
  }
}
