import 'package:flutter/material.dart';
import 'package:pdf_viewer/screens/home_screen.dart';
import 'package:flutter/services.dart';
import 'package:pdf_viewer/screens/pdf_viewer_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PDFViewer());
}

class PDFViewer extends StatefulWidget {
  const PDFViewer({super.key});

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  static const _channel = MethodChannel('aifile/pdf');
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openPdf') {
        _openPdf(call.arguments as String?);
      } else if (call.method == 'pdfError') {
        _showError();
      }
    });
    // The navigator must be ready before opening a cold-start PDF.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialPdf());
  }

  Future<void> _loadInitialPdf() async {
    try {
      _openPdf(await _channel.invokeMethod<String>('getInitialPdf'));
    } on MissingPluginException {
      // This channel is only available on Android.
    } on PlatformException {
      _showError();
    }
  }

  void _openPdf(String? path) {
    if (!mounted || path == null || path.isEmpty) return;
    _navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => PdfViewerScreen(filePath: path)),
      (route) => route.isFirst,
    );
  }

  void _showError() {
    if (!mounted) return;
    final context = _navigatorKey.currentContext;
    if (context == null) return;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cannot open PDF'),
        content: const Text('The shared PDF could not be read.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _channel.setMethodCallHandler(null);
    super.dispose();
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Flutter PDF Viewer Application',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.red.shade400)),
      home: const HomeScreen(),
    );
  }
}
