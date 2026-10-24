import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_viewer/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('aifile/pdf');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  testWidgets('Normal launch shows the PDF upload button', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      expect(call.method, 'getInitialPdf');
      return null;
    });

    await tester.pumpWidget(const PDFViewer());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.upload), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Unreadable initial PDF shows a dismissible error', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'PDF_ERROR');
    });

    await tester.pumpWidget(const PDFViewer());
    await tester.pumpAndSettle();

    expect(find.text('Cannot open PDF'), findsOneWidget);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byIcon(Icons.upload), findsOneWidget);
  });

  testWidgets('Running app handles a native PDF error', (tester) async {
    messenger.setMockMethodCallHandler(channel, (call) async => null);
    await tester.pumpWidget(const PDFViewer());
    await tester.pumpAndSettle();

    await messenger.handlePlatformMessage(
      channel.name,
      channel.codec.encodeMethodCall(
        const MethodCall('pdfError', 'Cannot read this PDF'),
      ),
      (_) {},
    );
    await tester.pumpAndSettle();

    expect(find.text('Cannot open PDF'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
