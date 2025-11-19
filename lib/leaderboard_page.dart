import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:io' show Platform;

class LeaderboardPage extends StatefulWidget {
  final String lobbyCode;
  const LeaderboardPage({super.key, required this.lobbyCode});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  // Fungsi untuk membersihkan sesi host dan kembali ke halaman utama
  Future<void> _clearHostSession() async {
    final prefs = await SharedPreferences.getInstance();
    // Hapus kode lobby Host
    await prefs.remove('last_lobby_code');

    if (mounted) {
      // Kembali ke halaman utama (Home/Landing Page) setelah membersihkan sesi
      // Gunakan popUntil untuk memastikan semua halaman stack di atas Home dihapus
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  // Fungsi untuk mendapatkan warna berdasarkan peringkat (tetap sama)
  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber[600]!; // Emas
      case 2:
        return Colors.grey[400]!; // Perak
      case 3:
        return Colors.brown[400]!; // Perunggu
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // --- PERUBAHAN UTAMA: TOMBOL BACK DINONAKTIFKAN ---
      // Ini menangani tombol Back Android/iOS atau gestur swipe.
      onWillPop: () async {
        return false; // Mengembalikan false untuk menonaktifkan tombol back
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        // --- APP BAR: Leading (Tombol Back) Dihapus, Actions (Tombol Exit) Dipertahankan ---
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 2,
          toolbarHeight: 80,
          automaticallyImplyLeading:
              false, // Penting: Menonaktifkan tombol back default
          title: Text(
            'Lobby: ${widget.lobbyCode}',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey),
          ),
          // Leading (Tombol Kembali) Dihapus di sini

          actions: [
            // --- TOMBOL EXIT SESSION DIPERTAHANKAN ---
            TextButton.icon(
              onPressed: _clearHostSession, // Fungsi logout/exit session
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text(
                'EXIT SESSION',
                style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 10),
          ],
        ),

        // --- BODY (Daftar Peringkat Tetap Sama) ---
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'PAPAN PERINGKAT LANGSUNG',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.blueAccent),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue[100]!),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('lobbies')
                        .doc(widget.lobbyCode)
                        .collection('teams')
                        // Kunci Utama: Skor (tertinggi)
                        .orderBy('score', descending: true)
                        // Kunci Kedua: Order (Tim 1, Tim 2, dst.) sebagai pemecah seri
                        .orderBy('order', descending: false)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('Tidak ada tim dalam lobi ini.'));
                      }

                      final teams = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: teams.length,
                        itemBuilder: (context, index) {
                          final teamData =
                              teams[index].data() as Map<String, dynamic>;

                          final teamName = teamData['team_name'] as String? ??
                              'Nama Tim Tidak Ditemukan';
                          final teamScore = teamData['score'] is int
                              ? teamData['score'] as int
                              : (teamData['score'] is num
                                  ? (teamData['score'] as num).toInt()
                                  : 0);

                          // Peringkat (rank) didasarkan pada posisi di ListView setelah diurutkan Firestore
                          final rank = index + 1;
                          final rankColor = _getRankColor(rank);

                          return Card(
                            elevation: rank <= 3 ? 8 : 2,
                            margin: const EdgeInsets.only(bottom: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: rankColor.withOpacity(0.7), width: 2),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 16),

                              // Peringkat (Leading)
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: rankColor,
                                  shape: BoxShape.circle,
                                  boxShadow: rank <= 3
                                      ? [
                                          BoxShadow(
                                              color: rankColor.withOpacity(0.5),
                                              blurRadius: 5)
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      color: rank <= 3
                                          ? Colors.white
                                          : Colors.black,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),

                              // Nama Tim (Title)
                              title: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  teamName,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: rankColor,
                                  ),
                                ),
                              ),

                              // Skor (Trailing)
                              trailing: Align(
                                widthFactor: 1.0,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '$teamScore Poin',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
