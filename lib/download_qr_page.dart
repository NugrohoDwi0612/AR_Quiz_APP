import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_db.dart';

class DownloadQRPage extends StatefulWidget {
  const DownloadQRPage({super.key});

  @override
  State<DownloadQRPage> createState() => _DownloadQRPageState();
}

class _DownloadQRPageState extends State<DownloadQRPage> {
  final FirebaseDB _db = FirebaseDB();
  late List<GlobalKey> _qrKeys;

  @override
  void initState() {
    super.initState();
    _qrKeys = [];
  }

  Future<void> _downloadQR(
      String data, String fileName, GlobalKey qrKey) async {
    // Minta izin penyimpanan
    var status = await Permission.storage.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Izin penyimpanan ditolak.')),
        );
      }
      return;
    }

    try {
      // Mengambil gambar QR dari widget (RenderRepaintBoundary)
      final RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 5.0);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Simpan ke galeri menggunakan image_gallery_saver_plus
      final result = await ImageGallerySaverPlus.saveImage(
        Uint8List.fromList(pngBytes),
        name: fileName,
      );

      //  Berikan umpan balik
      if (mounted) {
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$fileName berhasil diunduh ke galeri!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal mengunduh $fileName.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 100,
        leadingWidth: 120,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 12),
          child: Image.asset(
            'assets/images/logo.png',
            width: 100,
            height: 100,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Kembali',
              style: TextStyle(color: Colors.red, fontSize: 18),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text(
                'QR CODE',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: FutureBuilder<QuerySnapshot>(
                  future: _db.getQuizQuestions(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                          child: Text('Terjadi kesalahan: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                          child: Text('Tidak ada data soal ditemukan.'));
                    }

                    final quizDocs = snapshot.data!.docs;
                    _qrKeys =
                        List.generate(quizDocs.length, (index) => GlobalKey());

                    return ListView.builder(
                      itemCount: quizDocs.length,
                      itemBuilder: (context, index) {
                        final doc = quizDocs[index];
                        final qrCodeId = doc.id;
                        final String title = 'Soal ${index + 1}';
                        final qrKey = _qrKeys[index];

                        return _buildQRListItem(
                            context, title, qrCodeId, qrKey);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQRListItem(
      BuildContext context, String title, String qrData, GlobalKey qrKey) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RepaintBoundary(
            key: qrKey,
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 60.0,
              backgroundColor: Colors.white,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 18),
          ),
          ElevatedButton(
            onPressed: () => _downloadQR(
                qrData, title.replaceAll(' ', '_').toLowerCase(), qrKey),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}
