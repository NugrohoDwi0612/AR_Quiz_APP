import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_db.dart';
import 'ar_quiz_page.dart';

class LobbyPesertaPage extends StatefulWidget {
  final String lobbyCode;
  final String teamId;
  final String playerId;

  const LobbyPesertaPage({
    super.key,
    required this.lobbyCode,
    required this.teamId,
    required this.playerId,
  });

  @override
  State<LobbyPesertaPage> createState() => _LobbyPesertaPageState();
}

class _LobbyPesertaPageState extends State<LobbyPesertaPage> {
  final FirebaseDB _db = FirebaseDB();
  String _teamName = 'Memuat...';

  @override
  void initState() {
    super.initState();
    _fetchTeamName();
  }

  // Mengambil nama tim berdasarkan teamId
  Future<void> _fetchTeamName() async {
    try {
      // Asumsi _db.getTeamById mengembalikan DocumentSnapshot?
      final teamSnapshot =
          await _db.getTeamById(widget.lobbyCode, widget.teamId);

      // Periksa snapshot, lalu ambil data-nya
      if (teamSnapshot != null && teamSnapshot.exists) {
        // Ambil data (Map) dari snapshot
        final teamData = teamSnapshot.data() as Map<String, dynamic>?;

        // Pastikan data ada dan gunakan kunci 'team_name' (kunci yang umum digunakan)
        if (teamData != null && teamData.containsKey('team_name')) {
          setState(() {
            // Gunakan kunci 'team_name'
            _teamName = teamData['team_name'] as String;
          });
          return; // Keluar jika berhasil
        }
      }

      // Jika gagal/tidak ditemukan
      setState(() {
        _teamName = 'Tim Tidak Ditemukan';
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memuat nama tim: $e')),
        );
      }
      setState(() {
        _teamName = 'Error Memuat';
      });
    }
  }

  // FUNGSI INI DIPICU OLEH TOMBOL BACK FISIK/SISTEM
  // Hanya mengarahkan ke halaman utama (root) tanpa menghapus sesi.
  Future<bool> _goToMainScreen() async {
    if (mounted) {
      // Mengarahkan ke halaman pertama di stack navigasi
      Navigator.popUntil(context, (route) => route.isFirst);
    }
    // Mengembalikan 'false' membatalkan event 'pop' default
    return false;
  }

  // FUNGSI INI DIPICU OLEH TOMBOL 'KELUAR LOBI' DI UI
  // Menghapus sesi lokal sehingga peserta harus memasukkan kode lobi lagi.
  Future<void> _logoutLobby() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_lobby_code');
    await prefs.remove('last_team_id');
    await prefs.remove('last_player_id');

    if (mounted) {
      // Kembali ke halaman root (di mana input kode baru berada)
      Navigator.popUntil(context, (route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    // WillPopScope mencegat tombol kembali (back button)
    return WillPopScope(
      onWillPop:
          _goToMainScreen, // Tombol fisik hanya kembali tanpa menghapus sesi
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Hapus tombol kembali default
          title: const Text('Lobi Peserta'),
          actions: [
            // Tombol untuk keluar total (menghapus sesi)
            TextButton.icon(
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              label: const Text(
                'Keluar Lobi',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: _logoutLobby, // Memanggil fungsi logout total
            ),
          ],
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('lobbies')
              .doc(widget.lobbyCode)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            // Handle jika lobi tidak ada (telah ditutup oleh host)
            if (!snapshot.hasData || !snapshot.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                // *** PERBAIKAN LOGIKA DI SINI ***
                // Jika lobi hilang dari Firebase, HAPUS sesi lokal
                // dan kembali ke halaman utama (untuk input kode baru).
                _logoutLobby();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Lobi telah ditutup oleh host.')),
                );
              });
              return const Center(child: Text('Lobi tidak ditemukan.'));
            }

            final lobbyData = snapshot.data!.data() as Map<String, dynamic>;
            final lobbyStatus = lobbyData['status'] as String?;

            // Cek status, jika IN_GAME, navigasi ke ARQuizPage
            if (lobbyStatus == 'IN_GAME') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ARQuizPage(
                      lobbyCode: widget.lobbyCode,
                      teamId: widget.teamId,
                      playerId: widget.playerId,
                      initialScore: 0,
                    ),
                  ),
                );
              });
              return const Center(child: Text('Memulai permainan...'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLobbyInfoCard(
                      'Kode Lobi', widget.lobbyCode, Icons.vpn_key),
                  const SizedBox(height: 16),
                  _buildLobbyInfoCard('Tim Anda', _teamName, Icons.group),
                  const SizedBox(height: 24),
                  const Text(
                    'Anggota Tim:',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  _buildTeamPlayersList(),
                  const SizedBox(height: 30),
                  const Text(
                    'Menunggu Panitia memulai kuis...',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- Fungsi Widget Pembantu (Tidak Berubah) ---

  Widget _buildLobbyInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.indigo, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamPlayersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lobbies')
          .doc(widget.lobbyCode)
          .collection('teams')
          .doc(widget.teamId)
          .collection('players')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Text('Tidak ada anggota tim.'));
        }

        final players = snapshot.data!.docs;
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index].data() as Map<String, dynamic>;
            final playerName = player['name'] as String? ?? 'Pemain Anonim';
            final isCurrentPlayer = players[index].id == widget.playerId;

            return Card(
              margin: const EdgeInsets.only(bottom: 8.0),
              color: isCurrentPlayer ? Colors.indigo.shade50 : Colors.white,
              elevation: isCurrentPlayer ? 2 : 1,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isCurrentPlayer
                    ? const BorderSide(color: Colors.indigo, width: 2)
                    : BorderSide.none,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                      isCurrentPlayer ? Colors.indigo : Colors.grey.shade200,
                  child: Text(
                    playerName.isNotEmpty ? playerName[0].toUpperCase() : '?',
                    style: TextStyle(
                        color: isCurrentPlayer ? Colors.white : Colors.black87),
                  ),
                ),
                title: Text(
                  playerName,
                  style: TextStyle(
                    fontWeight:
                        isCurrentPlayer ? FontWeight.bold : FontWeight.normal,
                    color: Colors.black87,
                  ),
                ),
                trailing: isCurrentPlayer
                    ? const Chip(
                        label: Text('Anda', style: TextStyle(fontSize: 12)),
                        backgroundColor: Colors.indigo,
                        labelStyle: TextStyle(color: Colors.white),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}
