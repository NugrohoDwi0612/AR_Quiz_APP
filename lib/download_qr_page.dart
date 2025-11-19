import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_db.dart'; // Pastikan file ini ada

class DownloadQRPage extends StatefulWidget {
  const DownloadQRPage({super.key});

  @override
  State<DownloadQRPage> createState() => _DownloadQRPageState();
}

class _DownloadQRPageState extends State<DownloadQRPage> {
  final FirebaseDB _db = FirebaseDB();
  late List<GlobalKey> _qrKeys;
  PermissionStatus _storageStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _qrKeys = [];
    _requestPermission(); // Panggil fungsi permintaan izin saat inisialisasi
  }

  // --- FUNGSI BARU UNTUK MEMINTA DAN MEMERIKSA IZIN ---
  Future<void> _requestPermission() async {
    final status = await Permission.storage.request();
    if (mounted) {
      setState(() {
        _storageStatus = status;
      });
      // Beri umpan balik jika ditolak/dibatasi
      if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
      }
    }
  }

  // --- FUNGSI UNTUK MENAMPILKAN DIALOG JIKA IZIN DITOLAK PERMANEN ---
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Izin Penyimpanan Diperlukan'),
          content: const Text(
              'Untuk menyimpan QR Code, kami memerlukan izin penyimpanan. Silakan aktifkan di Pengaturan Aplikasi.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Buka Pengaturan'),
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings(); // Shortcut ke pengaturan aplikasi
              },
            ),
          ],
        );
      },
    );
  }

  // PERBAIKAN PADA FUNGSI _downloadQR
  Future<void> _downloadQR(
      String data, String fileName, GlobalKey qrKey) async {
    // 1. Cek status izin saat ini
    var status = await Permission.storage.status;

    // 2. Jika izin ditolak (tapi belum permanen), coba minta lagi
    if (status.isDenied) {
      status = await Permission.storage.request();
    }

    // 3. Jika izin ditolak permanen, tampilkan dialog Pengaturan
    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog();
      return;
    }

    // 4. Jika izin masih ditolak setelah permintaan (isDenied), hentikan dan beri feedback.
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Izin penyimpanan diperlukan untuk mengunduh.')),
        );
      }
      return;
    }

    // Jika status.isGranted, lanjutkan proses unduh
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

      // Berikan umpan balik sukses/gagal unduh
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
          SnackBar(content: Text('Terjadi kesalahan saat menyimpan: $e')),
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

              // --- TAMPILKAN WIDGET PERINGATAN JIKA IZIN DITOLAK ---
              if (_storageStatus.isPermanentlyDenied)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15.0),
                  child: Card(
                    color: Colors.red[50],
                    elevation: 1,
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded,
                          color: Colors.red),
                      title: const Text('Izin Penyimpanan Ditolak Permanen'),
                      subtitle: const Text(
                          'Anda harus mengaktifkan izin secara manual di pengaturan perangkat.'),
                      trailing: TextButton(
                        onPressed: openAppSettings, // Shortcut ke pengaturan
                        child: const Text('Pengaturan',
                            style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  ),
                ),
              // --------------------------------------------------------

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
                    // Inisialisasi _qrKeys di sini karena jumlah dokumen sudah diketahui
                    if (_qrKeys.length != quizDocs.length) {
                      _qrKeys = List.generate(
                          quizDocs.length, (index) => GlobalKey());
                    }

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
            // Tombol download akan bekerja jika izin sudah didapatkan, atau akan memicu permintaan ulang
            onPressed: () => _downloadQR(
                qrData, title.replaceAll(' ', '_').toLowerCase(), qrKey),
            child: const Text('Download'),
          ),
        ],
      ),
    );
  }
}
