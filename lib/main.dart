import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'panitia_page.dart';
import 'peserta_page.dart';
import 'package:ar_quiz_app/firebase_db.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Panggil fungsi untuk menambahkan soal bila soal sudah di database, tutup code
  _addDummyQuestions();

  runApp(const MyApp());
}

final FirebaseDB db = FirebaseDB();

// Fungsi untuk menambahkan soal dummy bila soal sudah di database, tutup code
// ... (blok _addDummyQuestions tetap tidak berubah)
Future<void> _addDummyQuestions() async {
  final List<Map<String, dynamic>> rawQuestions = [
    {
      'newsText':
          'Sebuah video menampilkan rumah dan jalan rusak di Tuban yang diklaim terjadi akibat gempa bumi pada awal bulan. Namun setelah ditelusuri, video tersebut ternyata merupakan rekaman lama dari kejadian berbeda dan tidak berkaitan dengan gempa Tuban.',
      'questionText':
          'Apakah informasi tersebut benar terjadi di Tuban baru-baru ini?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Karena video tersebut adalah rekaman lama dan terindikasi berita hoax.',
    },
    {
      'newsText':
          'Sebuah video menampilkan rumah dan jalan rusak di Tuban yang diklaim terjadi akibat gempa bumi pada awal bulan. Namun setelah ditelusuri, video tersebut ternyata merupakan rekaman lama dari kejadian berbeda dan tidak berkaitan dengan gempa Tuban.',
      'questionText': 'Apakah informasi tersebut benar terjadi di Tuban?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation':
          'Karena video tersebut benar terjadi di Tuban, namun video tersebut merupakan video rekaman lama.',
    },
    {
      'newsText':
          'Sebuah postingan mengklaim bahwa vaksin Covid-19 mengandung chip dan manusia dijadikan kelinci percobaan oleh pemerintah. Informasi ini telah dibantah oleh Kemenkes dan WHO karena tidak memiliki dasar ilmiah.',
      'questionText':
          'Apakah informasi mengenai vaksin yang mengandung chip terbukti benar?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation': 'Karena berita ini hoaks tanpa bukti ilmiah.',
    },
    {
      'newsText':
          'Sebuah unggahan menyebutkan bahwa seorang pejabat tinggi di Indonesia akan memberikan bantuan langsung tunai sebesar Rp 10 juta kepada masyarakat melalui pendaftaran di situs tertentu dengan memasukkan nomor KTP. Banyak warganet membagikan tautan tersebut karena menganggapnya program resmi pemerintah.',
      'questionText':
          'Apakah informasi dalam berita tersebut dapat dipercaya sebagai program resmi pemerintah?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Program resmi pemerintah tidak dilakukan melalui pendaftaran situs yang tidak terverifikasi.',
    },
    {
      'newsText':
          'Sebuah unggahan viral menampilkan foto vaksin Covid-19 dengan label “chip tracking device” di bagian bawah botolnya. Disebutkan bahwa chip tersebut berfungsi untuk memantau pergerakan manusia setelah divaksin.',
      'questionText':
          'Apakah berita ini menggambarkan informasi yang benar tentang isi vaksin Covid-19?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Klaim chip tracking dalam vaksin adalah hoaks yang tidak berdasar.',
    },
    {
      'newsText':
          'Tersebar kabar bahwa pemerintah akan menutup seluruh akses media sosial selama satu minggu untuk menghindari penyebaran informasi palsu menjelang pemilihan umum. Beberapa akun anonim di X (Twitter) menyebut keputusan tersebut sudah ditandatangani oleh pejabat Kemenkominfo.',
      'questionText':
          'Apakah berita tersebut kemungkinan berasal dari sumber resmi pemerintah?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Tidak ada unggahan maupun postingan tentang informasi tersebut yang disiarkan melalui berita tv nasional, maupun dari unggah medsos dari kemenkominfo, sehingga bisa dikatakan berita tersebut hoax.',
    },
    {
      'newsText':
          'Badan Meteorologi, Klimatologi, dan Geofisika (BMKG) mengonfirmasi adanya aktivitas gempa berkekuatan 6,1 SR di wilayah selatan Jawa Timur yang tidak berpotensi tsunami. Informasi tersebut disampaikan melalui situs resmi dan aplikasi BMKG pada hari yang sama.',
      'questionText':
          'Apakah informasi ini dapat dikategorikan sebagai berita yang akurat dan terverifikasi?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation': 'Informasi berasal dari sumber resmi dan kredibel (BMKG).',
    },
    {
      'newsText':
          'Kementerian Kesehatan mengeluarkan imbauan kepada masyarakat untuk tidak membeli obat sirup anak yang belum memiliki izin edar BPOM. Kebijakan ini dikeluarkan setelah adanya temuan bahan berbahaya dalam beberapa produk impor.',
      'questionText':
          'Apakah isi berita ini merupakan kebijakan resmi dari lembaga pemerintah?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation':
          'Kementerian Kesehatan mengeluarkan imbauan, sehingga berita tersebut valid dan resmi.',
    },
    {
      'newsText':
          'Otoritas Jasa Keuangan (OJK) mengingatkan masyarakat untuk berhati-hati terhadap investasi bodong yang menjanjikan keuntungan 10 % per hari tanpa risiko. Pernyataan resmi disampaikan melalui konferensi pers dan laman resmi OJK.',
      'questionText':
          'Apakah berita ini termasuk peringatan yang berasal dari lembaga kredibel?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation': 'OJK adalah lembaga resmi yang mengeluarkan peringatan.',
    },
    {
      'newsText':
          'Pemerintah Kota Surabaya meluncurkan aplikasi pelaporan bencana berbasis lokasi yang memungkinkan warga mengirimkan foto kondisi lingkungan saat hujan lebat untuk membantu petugas. Aplikasi ini diumumkan melalui situs resmi Pemkot dan media lokal.',
      'questionText':
          'Apakah berita ini termasuk informasi yang dapat diverifikasi dari sumber resmi daerah?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation': 'Informasi berasal dari situs resmi Pemkot Surabaya.',
    },
    {
      'newsText':
          'Sebuah organisasi non-pemerintah menerbitkan laporan bahwa lebih dari 80 % ibu hamil di wilayah rural Indonesia menggunakan jamu tradisional tanpa pengawasan medis, dan menyarankan pembentukan pusat pengawasan jamu oleh pemerintah daerah.',
      'questionText':
          'Apakah laporan ini adalah hasil riset lapangan yang telah dipublikasikan secara terbuka oleh organisasi tersebut?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation':
          'Laporan dari organisasi non-pemerintah dapat diterima sebagai hasil riset lapangan yang dipublikasikan secara terbuka.',
    },
    {
      'newsText':
          'Sebuah video yang viral menunjukkan seorang tokoh publik menerima paket uang tunai di bandara internasional, lalu diklaim sebagai bukti korupsi variabel tinggi di lembaga pemerintahan.',
      'questionText':
          'Apakah video tersebut dapat dijadikan bukti sah untuk mendukung tuduhan korupsi resmi terhadap lembaga pemerintahan?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Video viral tidak memenuhi syarat sebagai bukti sah tanpa proses investigasi formal.',
    },
    {
      'newsText':
          'Laporan sebuah media terpercaya menyebut bahwa terjadi lonjakan ekspor produk kerajinan Indonesia ke pasar Eropa sebesar 30 % pada semester pertama tahun ini dibandingkan semester yang sama tahun lalu.',
      'questionText':
          'Apakah informasi ini dapat dianggap sebagai berita benar tentang performa ekspor kerajinan Indonesia?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation':
          'Laporan dari media terpercaya menunjukkan verifikasi data ekonomi.',
    },
    {
      'newsText':
          'Sebuah situs massa menampilkan artikel yang mengklaim bahwa pemerintah akan membangkitkan 50 pembangkit listrik tenaga nuklir kecil di lima wilayah Indonesia dalam lima tahun ke depan.',
      'questionText':
          'Apakah klaim tersebut benar merupakan rencana resmi pemerintah yang diumumkan dalam pertemuan publik?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Rencana strategis besar harus dikonfirmasi melalui pernyataan resmi pemerintah.',
    },
    {
      'newsText':
          'Sebuah studi independen mempublikasikan hasil bahwa pengguna internet yang secara aktif mengecek kebenaran berita sebelum membagikannya memiliki kecenderungan dua kali lebih besar untuk tidak menyebar berita hoaks dibanding mereka yang tidak aktif melakukan pengecekan.',
      'questionText':
          'Apakah hasil studi ini bisa diterima sebagai temuan yang valid untuk menyimpulkan perilaku pengguna internet?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation':
          'Hasil studi independen yang dipublikasikan secara terbuka dapat diterima sebagai temuan yang valid.',
    },
    {
      'newsText':
          'Sebuah portal berita lokal menulis bahwa pemerintah akan menerapkan pajak tambahan 2% untuk seluruh transaksi belanja online mulai tahun depan sebagai kompensasi subsidi BBM. Artikel tersebut menyertakan logo Kementerian Keuangan dan tangkapan layar “draf kebijakan”.',
      'questionText':
          'Apakah berita tersebut termasuk kebijakan resmi yang telah diumumkan pemerintah?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Kebijakan pajak resmi diumumkan oleh Kemenkeu melalui pengumuman resmi, bukan draf di portal berita lokal.',
    },
    {
      'newsText':
          'Di media sosial beredar unggahan yang menyebutkan bahwa semua SIM (Surat Izin Mengemudi) akan diganti menjadi kartu digital berbentuk aplikasi di ponsel dan kartu fisik tidak lagi berlaku mulai tahun ini.',
      'questionText':
          'Apakah informasi tersebut menggambarkan kebijakan resmi Polri terkait digitalisasi SIM?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'SIM digital saat ini bersifat opsional atau pendamping, bukan menggantikan kartu fisik sepenuhnya.',
    },
    {
      'newsText':
          'Tersebar informasi bahwa aplikasi chat populer akan memungut biaya langganan bulanan sebesar Rp10.000 untuk mengakses fitur pesan terenkripsi mulai tahun depan, dan pengguna yang tidak membayar tidak bisa lagi mengirim pesan.',
      'questionText':
          'Apakah informasi tersebut sesuai dengan pengumuman resmi dari perusahaan penyedia aplikasi?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Pengumuman resmi dari perusahaan penyedia layanan chat populer akan disiarkan secara luas dan resmi.',
    },
    {
      'newsText':
          'Kementerian Komunikasi dan Informatika (Kominfo) terus meningkatkan literasi digital masyarakat melalui program “Cek Fakta Sebelum Sebar”, dengan fokus utama pada siswa dan mahasiswa.',
      'questionText':
          'Apakah program literasi digital ini merupakan kegiatan resmi dari Kominfo?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation':
          'Program literasi digital adalah kegiatan resmi dari Kominfo.',
    },
    {
      'newsText':
          'Bank Indonesia mengumumkan peluncuran QRIS versi 2.0 dengan peningkatan keamanan dan batas transaksi lebih tinggi untuk mendukung sistem pembayaran digital nasional.',
      'questionText':
          'Apakah berita ini benar merupakan bagian dari kebijakan resmi Bank Indonesia?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation':
          'Bank Indonesia bertanggung jawab atas regulasi sistem pembayaran nasional seperti QRIS.',
    },
    {
      'newsText':
          'Universitas Gadjah Mada (UGM) meluncurkan sistem pendaftaran magang berbasis web yang terhubung langsung dengan perusahaan mitra untuk mempermudah mahasiswa mencari tempat praktik kerja.',
      'questionText':
          'Apakah berita ini menggambarkan inisiatif nyata yang dilakukan oleh UGM?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation':
          'Peluncuran sistem pendaftaran magang adalah inisiatif nyata UGM.',
    },
    {
      'newsText':
          'Sebuah artikel daring menyatakan bahwa semua kendaraan pribadi di Jakarta akan diwajibkan menggunakan pelat nomor berwarna hijau mulai tahun depan sebagai tanda bebas emisi karbon.',
      'questionText':
          'Apakah kebijakan penggunaan pelat hijau sudah ditetapkan oleh pemerintah provinsi Jakarta?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Perubahan regulasi kendaraan besar harus ditetapkan oleh pemerintah provinsi dan lembaga terkait secara resmi.',
    },
    {
      'newsText':
          'Sebuah unggahan viral menunjukkan foto jalan rusak yang diklaim sebagai proyek baru pemerintah yang gagal di wilayah Jawa Barat. Namun, unggahan itu tidak mencantumkan waktu atau lokasi pasti kejadian.',
      'questionText':
          'Apakah unggahan tersebut dapat dipastikan sebagai bukti proyek gagal pemerintah?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Klaim tanpa konteks (waktu, lokasi, sumber) tidak dapat dipastikan kebenarannya.',
    },
    {
      'newsText':
          'Bank Indonesia mengumumkan bahwa transaksi digital menggunakan QRIS telah mencapai lebih dari 1 miliar transaksi pada tahun 2024, menunjukkan peningkatan pesat penggunaan pembayaran nontunai.',
      'questionText':
          'Apakah data tersebut menggambarkan hasil pencatatan resmi Bank Indonesia?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation':
          'Data tersebut merupakan hasil pencatatan resmi Bank Indonesia.',
    },
    {
      'newsText':
          'Sebuah unggahan di Facebook mengklaim bahwa semua akun media sosial akan dikenai pajak tahunan sebesar Rp50.000 mulai 2025 sebagai bagian dari regulasi baru pemerintah tentang ekonomi digital.',
      'questionText':
          'Apakah kebijakan pajak akun media sosial tersebut benar telah diberlakukan?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Kebijakan pajak membutuhkan pengumuman resmi dan legislasi yang kredibel.',
    },
    {
      'newsText':
          'Beberapa situs menuliskan bahwa Google akan menutup layanan Gmail pada tahun 2026 karena biaya operasional server yang terlalu tinggi dan akan mengganti dengan layanan berbayar penuh.',
      'questionText':
          'Apakah benar Google telah mengumumkan rencana penutupan Gmail pada 2026?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Tidak',
      'explanation':
          'Penutupan layanan Google akan diumumkan melalui kanal resmi mereka.',
    },
    {
      'newsText':
          'Pemerintah Indonesia menargetkan penggunaan kendaraan listrik mencapai dua juta unit pada tahun 2030 sebagai bagian dari komitmen pengurangan emisi karbon.',
      'questionText':
          'Apakah target ini termasuk dalam rencana transisi energi pemerintah?',
      'options': ['Iya', 'Tidak'],
      'correctAnswer': 'Iya',
      'explanation':
          'Target kendaraan listrik adalah bagian dari rencana pemerintah untuk mengurangi emisi karbon.',
    },
  ];

  try {
    for (int i = 0; i < rawQuestions.length; i++) {
      final questionData = rawQuestions[i];
      // Generate ID unik untuk QR Code: QR01, QR02, ...
      final String qrId = 'QR${(i + 1).toString().padLeft(2, '0')}';

      // Panggil fungsi addQuizQuestion dari FirebaseDB Anda
      await db.addQuizQuestion(
        qrCodeId: qrId, // Ini akan menjadi nama dokumen di koleksi 'qrcodes'
        questionText: questionData['questionText']!,
        options: questionData['options'] as List<String>,
        correctAnswer: questionData['correctAnswer']!,
        points: 10, // Menetapkan poin default (misalnya 10)
      );

      // Secara opsional, tambahkan juga 'newsText' dan 'explanation'
      // ke dalam dokumen QR Code jika diperlukan oleh aplikasi (saran)
      await FirebaseFirestore.instance.collection('qrcodes').doc(qrId).update({
        'news_text': questionData['newsText'],
        'explanation': questionData['explanation'],
      });
    }

    print(
        '${rawQuestions.length} dummy questions added successfully as QR Codes!');
  } catch (e) {
    print('Error adding dummy QR questions: $e');
  }
}

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

  // Fungsi utilitas untuk menampilkan SnackBar
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // >>> FUNGSI UTAMA UNTUK MENGHANDLE NAVIGASI DAN KONTROL AKSES <<<
  Future<void> _handleNavigation(
      BuildContext context, String role, Widget destinationPage) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastLobbyCode = prefs.getString('last_lobby_code');
    final String? lastPlayerId =
        prefs.getString('last_player_id'); // Identifikasi Peserta

    if (role == 'PANITIA') {
      // PANITIA: Cek apakah ada sesi Peserta yang aktif
      if (lastLobbyCode != null && lastPlayerId != null) {
        // Jika ada lastLobbyCode dan lastPlayerId, berarti perangkat ini terdaftar sebagai Peserta
        _showSnackBar(context,
            'Akses ditolak. Anda sedang terhubung sebagai **Peserta** di lobi $lastLobbyCode.');
        return;
      }
    } else if (role == 'PESERTA') {
      // PESERTA: Cek apakah perangkat ini sedang menjadi Host aktif
      // Host diidentifikasi hanya dengan lastLobbyCode (dari BuatLobbyPage) dan tidak ada lastPlayerId
      // Kita akan cek lebih dulu apakah Host ID di Firestore sama dengan Local User ID
      if (lastLobbyCode != null && lastPlayerId == null) {
        try {
          // Asumsi BuatLobbyPage menyimpan last_lobby_code hanya untuk host/panitia,
          // dan host_id di Firestore sama dengan local_user_id.
          // Cek lebih dalam ke Firestore untuk verifikasi Host/Panitia:
          final lobbyDoc = await db.getLobbyData(lastLobbyCode);
          final String? localUserId = prefs.getString('local_user_id');
          final String? hostId =
              lobbyDoc.exists ? lobbyDoc.get('host_id') : null;
          final String? status =
              lobbyDoc.exists ? lobbyDoc.get('status') : null;

          // Jika lobi ada, status WAITING/IN_GAME, DAN ID lokal ini adalah Host-nya
          if (lobbyDoc.exists &&
              localUserId == hostId &&
              (status == 'WAITING' || status == 'IN_GAME')) {
            _showSnackBar(context,
                'Akses ditolak. Anda sedang terhubung sebagai **Panitia** di lobi $lastLobbyCode.');
            return;
          }
        } catch (e) {
          // Abaikan error DB, tetap biarkan navigasi sebagai Peserta
        }
      }
    }

    // Jika lolos pengecekan, lakukan navigasi
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => destinationPage),
    );
  }
  // >>> AKHIR FUNGSI _handleNavigation <<<

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
              // Panggil fungsi handle
              _handleNavigation(context, 'PANITIA', const PanitiaPage());
            }),
            const SizedBox(height: 20),

            // Tombol "PESERTA"
            _buildCustomButton(context, 'PESERTA', () {
              // Panggil fungsi handle
              _handleNavigation(context, 'PESERTA', const PesertaPage());
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
    // ... (widget _buildCustomButton tetap tidak berubah)
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
    // ... (fungsi _showExitDialog tetap tidak berubah)
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
    // ... (widget _buildDialogButton tetap tidak berubah)
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
