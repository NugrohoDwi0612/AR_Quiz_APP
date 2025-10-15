import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'panitia_page.dart';
import 'peserta_page.dart';
import 'package:ar_quiz_app/firebase_db.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Panggil fungsi untuk menambahkan soal bila soal sudah di database, tutup code
  // _addDummyQuestions();

  runApp(const MyApp());
}

final FirebaseDB db = FirebaseDB();

// Fungsi untuk menambahkan soal dummy bila soal sudah di database, tutup code
// void _addDummyQuestions() {
//   db.addQuizQuestion(
//     qrCodeId: 'soal_1',
//     questionText: 'Apa yang dimaksud dengan "hoax"?',
//     options: [
//       'Berita asli yang disalahpahami',
//       'Informasi yang disebarkan untuk bersenang-senang',
//       'Informasi palsu yang disengaja untuk menyesatkan',
//       'Opini pribadi yang tidak didukung fakta'
//     ],
//     correctAnswer: 'Informasi palsu yang disengaja untuk menyesatkan',
//     points: 100,
//   );

//   db.addQuizQuestion(
//     qrCodeId: 'soal_2',
//     questionText: 'Salah satu ciri utama berita hoax adalah...',
//     options: [
//       'Menggunakan sumber terpercaya',
//       'Judul yang netral dan informatif',
//       'Menciptakan kebencian dan kepanikan',
//       'Memiliki data dan statistik yang lengkap'
//     ],
//     correctAnswer: 'Menciptakan kebencian dan kepanikan',
//     points: 100,
//   );

//   db.addQuizQuestion(
//     qrCodeId: 'soal_3',
//     questionText:
//         'Berita yang dibuat dengan tujuan memecah belah masyarakat sering disebut sebagai...',
//     options: ['Clickbait', 'Propaganda', 'Disinformasi', 'Misinformasi'],
//     correctAnswer: 'Disinformasi',
//     points: 150,
//   );

//   db.addQuizQuestion(
//     qrCodeId: 'soal_4',
//     questionText:
//         'Apa langkah pertama yang harus dilakukan ketika menerima informasi yang meragukan?',
//     options: [
//       'Segera bagikan ke teman',
//       'Tanyakan ke media sosial',
//       'Verifikasi kebenaran informasi tersebut',
//       'Abaikan saja tanpa melakukan apa-apa'
//     ],
//     correctAnswer: 'Verifikasi kebenaran informasi tersebut',
//     points: 150,
//   );

//   db.addQuizQuestion(
//     qrCodeId: 'soal_5',
//     questionText:
//         'Situs web berita yang kredibel biasanya memiliki ciri-ciri...',
//     options: [
//       'Nama domain yang tidak dikenal',
//       'Alamat yang jelas dan kontak redaksi',
//       'Isi berita yang berlebihan',
//       'Iklan pop-up yang mengganggu'
//     ],
//     correctAnswer: 'Alamat yang jelas dan kontak redaksi',
//     points: 100,
//   );

//   db.addQuizQuestion(
//     qrCodeId: 'soal_6',
//     questionText:
//         'Jenis hoax yang mencoba mempengaruhi emosi pembaca dengan judul sensasional disebut...',
//     options: ['Clickbait', 'Malware', 'Hoax finansial', 'Deepfake'],
//     correctAnswer: 'Clickbait',
//     points: 150,
//   );

//   db.addQuizQuestion(
//     qrCodeId: 'soal_7',
//     questionText: 'Mengapa menyebarkan hoax dapat berbahaya bagi masyarakat?',
//     options: [
//       'Menghabiskan kuota internet',
//       'Membuat orang lebih pintar',
//       'Dapat merusak reputasi dan memicu konflik sosial',
//       'Tidak ada efek serius'
//     ],
//     correctAnswer: 'Dapat merusak reputasi dan memicu konflik sosial',
//     points: 200,
//   );

//   db.addQuizQuestion(
//     qrCodeId: 'soal_8',
//     questionText:
//         'Bagaimana cara memverifikasi kebenaran sebuah foto atau video?',
//     options: [
//       'Bertanya di grup WhatsApp',
//       'Mencari sumber asli atau menggunakan pencarian gambar terbalik (reverse image search)',
//       'Mengandalkan ingatan pribadi',
//       'Tidak perlu dicek, langsung percaya'
//     ],
//     correctAnswer:
//         'Mencari sumber asli atau menggunakan pencarian gambar terbalik (reverse image search)',
//     points: 200,
//   );

//   db.addQuizQuestion(
//     qrCodeId: 'soal_9',
//     questionText:
//         'Di Indonesia, lembaga pemerintah yang berwenang menangani isu hoax adalah...',
//     options: [
//       'Kementerian Lingkungan Hidup dan Kehutanan',
//       'Kementerian Komunikasi dan Informatika (Kominfo)',
//       'Kementerian Pariwisata',
//       'Kementerian Pertahanan'
//     ],
//     correctAnswer: 'Kementerian Komunikasi dan Informatika (Kominfo)',
//     points: 150,
//   );

//   db.addQuizQuestion(
//     qrCodeId: 'soal_10',
//     questionText: 'Seringkali, berita hoax disebarkan melalui...',
//     options: [
//       'Jurnal ilmiah',
//       'Media sosial dan aplikasi pesan instan',
//       'Ensiklopedia resmi',
//       'Dokumen pemerintah yang rahasia'
//     ],
//     correctAnswer: 'Media sosial dan aplikasi pesan instan',
//     points: 100,
//   );
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'PeaceSans',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo dan Teks Hoax Hunter AR
            Image.asset(
              'assets/images/logo.png',
              width: 250,
            ),
            const SizedBox(height: 80),

            // Tombol "PANITIA"
            _buildCustomButton(context, 'PANITIA', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PanitiaPage()),
              );
            }),
            const SizedBox(height: 20),

            // Tombol "PESERTA"
            _buildCustomButton(context, 'PESERTA', () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PesertaPage()),
              );
            }),
            const SizedBox(height: 20),

            // Tombol "KELUAR"
            _buildCustomButton(context, 'KELUAR', () {
              _showExitDialog(context);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomButton(
      BuildContext context, String text, VoidCallback onPressed) {
    return Container(
      width: 250,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(30),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: const Text(
            'Apakah anda yakin ingin keluar?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            _buildDialogButton('Yes', () {
              Navigator.of(context).pop();
              exit(0); // Menutup aplikasi
            }),
            const SizedBox(width: 10),
            _buildDialogButton('No', () {
              Navigator.of(context).pop(); // Hanya menutup dialog
            }),
          ],
        );
      },
    );
  }

  Widget _buildDialogButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: Colors.white,
        side: const BorderSide(color: Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
      child: Text(text),
    );
  }
}
