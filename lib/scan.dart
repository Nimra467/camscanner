import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart'; // For saving images and PDFs
import 'package:pdf/pdf.dart'; // PDF generation package
import 'package:pdf/widgets.dart' as pw; // PDF widgets
import 'dart:async';
import 'package:cunning_document_scanner/cunning_document_scanner.dart';

class CamScannerApp extends StatefulWidget {
  const CamScannerApp({Key? key}) : super(key: key);

  @override
  State<CamScannerApp> createState() => _CamScannerAppState();
}

class _CamScannerAppState extends State<CamScannerApp> {
  List<String> _pictures = [];

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Scanner App'),
          actions: [
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: () => saveImages(context), // Passing context here
            ),
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => convertToPdf(context), // Passing context here
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: onPressed, // Scan new images
                  child: const Text("Add Pictures"),
                ),
              ),
              // Display scanned pictures
              for (var picture in _pictures)
                Stack(
                  children: [
                    Image.file(File(picture)),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () =>
                            deleteImage(picture), // Delete scanned image
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Trigger the scanner to scan images
  void onPressed() async {
    List<String> pictures;
    try {
      pictures = await CunningDocumentScanner.getPictures() ?? [];
      if (!mounted) return;
      setState(() {
        _pictures.addAll(pictures);
      });
    } catch (exception) {
      print("Error scanning document: $exception");
    }
  }

  // Delete an image from the list
  void deleteImage(String imagePath) {
    setState(() {
      _pictures.remove(imagePath);
      File(imagePath).deleteSync(); // Delete the image file
    });
  }

  // Save images to local storage
  Future<void> saveImages(BuildContext context) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      for (var picture in _pictures) {
        final imageFile = File(picture);
        final newImagePath =
            '${directory.path}/${imageFile.uri.pathSegments.last}';
        imageFile.copySync(newImagePath);
        print('Saved image: $newImagePath');
      }
      showSnackBar(context, "Images saved successfully!"); // Show feedback
    } catch (e) {
      print("Error saving images: $e");
      showSnackBar(context, "Failed to save images!"); // Show error feedback
    }
  }

  // Convert scanned images to PDF
  // Convert scanned images to PDF
  Future<void> convertToPdf(BuildContext context) async {
    if (!mounted) return; // Check if the widget is mounted

    if (_pictures.isEmpty) {
      print('No images to convert to PDF');
      showSnackBar(context, 'No images to convert to PDF!');
      return;
    }

    // Create a new PDF document
    final pdf = pw.Document();

    for (var picture in _pictures) {
      final image = pw.MemoryImage(File(picture).readAsBytesSync());

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image),
            );
          },
        ),
      );
    }

    // Save the PDF to local storage
    try {
      final output = await getApplicationDocumentsDirectory();
      final file = File("${output.path}/scanned_documents.pdf");
      await file.writeAsBytes(await pdf.save());
      print("PDF saved at: ${file.path}");

      // Use Future.delayed to ensure the Scaffold is built before showing the SnackBar
      Future.delayed(Duration.zero, () {
        if (mounted) {
          showSnackBar(context, "PDF saved successfully at: ${file.path}");
        }
      });
    } catch (e) {
      print("Error saving PDF: $e");
      Future.delayed(Duration.zero, () {
        if (mounted) {
          showSnackBar(context, "Failed to save PDF!");
        }
      });
    }
  }

  // Show feedback using SnackBar
  void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
