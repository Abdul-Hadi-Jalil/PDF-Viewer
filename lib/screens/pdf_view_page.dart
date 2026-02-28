import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';

class PdfViewPageFromAssets extends StatelessWidget {
  const PdfViewPageFromAssets({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
      body: Padding(
        padding: const EdgeInsets.only(top: 100.0),
        child:
            PDF(
              autoSpacing: false,
              pageFling: false,
              backgroundColor: Colors.grey,
              onError: (error) {
                print(error.toString());
              },
              onPageError: (page, error) {
                print('$page: ${error.toString()}');
              },
            ).fromAsset(
              'assets/past papers/Probability and Statistics/PROB_FinalTerm_F22.pdf',
            ),
      ),
    );
  }
}
