import 'package:flutter/material.dart';
import 'package:pdf_viewer/drive%20urls/books_url.dart';
import 'package:url_launcher/url_launcher.dart';

class ShowPdfFromUrl extends StatefulWidget {
  const ShowPdfFromUrl({super.key});

  @override
  State<ShowPdfFromUrl> createState() => _ShowPdfFromUrlState();
}

class _ShowPdfFromUrlState extends State<ShowPdfFromUrl> {
  Future<void> _openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Show PDF from URL')),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              title: const Text('Electronic Devices by Floyd'),
              onTap: () => _openUrl(ELECTRONIC_DEVICES_BY_FLOYD_URL),
            ),
          ],
        ),
      ),
    );
  }
}
