import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:convert';
import 'ar_quiz_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: QRScannerPage(),
    );
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isCameraActive = true;

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        controller!.pauseCamera();
      }
      controller!.resumeCamera();
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    if (_isCameraActive) {
      controller.scannedDataStream.listen((scanData) {
        if (scanData.code != null) {
          try {
            final quizData =
                json.decode(scanData.code!) as Map<String, dynamic>;
            _isCameraActive = false;
            controller.pauseCamera();

            Navigator.of(context)
                .push(
                  MaterialPageRoute(
                    builder: (context) => ARQuizPage(quizData: quizData),
                  ),
                )
                .then((_) {
                  _isCameraActive = true;
                  controller.resumeCamera();
                });
          } catch (e) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Data QR tidak valid: $e')));
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan QR Code Soal',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.deepPurple,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 300,
              ),
            ),
          ),
          const Expanded(
            flex: 1,
            child: Center(
              child: Text(
                'Arahkan kamera ke QR code yang berisi data soal.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
