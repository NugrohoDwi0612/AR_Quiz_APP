import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_db.dart';
import 'leaderboard_page.dart';
import 'lobby_peserta_page.dart'; // <<< PASTIKAN FILE INI ADA!

class BuatLobbyPage extends StatefulWidget {
  const BuatLobbyPage({super.key});

  @override
  State<BuatLobbyPage> createState() => _BuatLobbyPageState();
}

class _BuatLobbyPageState extends State<BuatLobbyPage> {
  final FirebaseDB _db = FirebaseDB();
  String? lobbyCode;
  int _selectedTeamCount = 2;
  bool _isLobbyCreated = false;

  // Variabel Host ID dan Rejoin
  String? _localUserId; // ID unik perangkat
  String? _lastLobbyCode;
  String? _actualHostId; // ID host yang disimpan di Firestore

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Fungsi untuk mendapatkan atau membuat User ID lokal
  Future<void> _getOrCreateLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('local_user_id');

    if (storedId == null) {
      // Membuat ID unik sederhana (timestamp + microsecond)
      storedId = DateTime.now().millisecondsSinceEpoch.toString() +
          (DateTime.now().microsecondsSinceEpoch % 1000).toString();
      await prefs.setString('local_user_id', storedId);
    }

    setState(() {
      _localUserId = storedId;
      _lastLobbyCode = prefs.getString('last_lobby_code');
    });
  }

  // BARU: Fungsi untuk mengecek sesi peserta yang aktif dan mengarahkan kembali
  Future<bool> _checkParticipantSession() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lobbyCode = prefs.getString('last_lobby_code');
    final String? teamId = prefs.getString('last_team_id');
    final String? playerId =
        prefs.getString('last_player_id'); // Kunci identifikasi Peserta

    // Jika semua token Peserta ada, berarti perangkat ini terdaftar sebagai PESERTA
    if (lobbyCode != null && teamId != null && playerId != null) {
      try {
        // Verifikasi status lobi di database
        final lobbyDoc = await _db.getLobbyData(lobbyCode);

        if (lobbyDoc.exists) {
          final status = lobbyDoc.get('status');
          // Jika lobi masih aktif (WAITING atau IN_GAME), paksa pindah ke halaman Peserta
          if ((status == 'WAITING' || status == 'IN_GAME') && mounted) {
            // LARANG AKSES HOST: Arahkan ke halaman Lobi Peserta
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                // Harap pastikan LobbyPesertaPage menerima parameter ini
                builder: (context) => LobbyPesertaPage(
                  lobbyCode: lobbyCode,
                  teamId: teamId,
                  playerId: playerId,
                ),
              ),
            );
            _showSnackBar(
                'Akses ditolak. Anda sedang terhubung sebagai Peserta.');
            return true; // Akses ditolak dan dinavigasi
          }
        }
      } catch (e) {
        // Abaikan error jaringan/db, biarkan user mencoba sebagai Host
      }
    }
    return false; // Boleh melanjutkan ke pembuatan lobi Host
  }

  // Fungsi untuk mengecek dan me-rejoin lobby yang belum selesai
  Future<bool> _checkLastLobby() async {
    if (_lastLobbyCode != null && _localUserId != null) {
      try {
        final lobbyDoc = await _db.getLobbyData(_lastLobbyCode!);

        if (lobbyDoc.exists) {
          final status = lobbyDoc.get('status');
          final hostId = lobbyDoc.get('host_id');

          // 1. Tentukan apakah perangkat ini adalah Host/Panitia
          final isHost = hostId == _localUserId;

          // Panitia/Host hanya mengurus lobi yang dibuatnya
          if (isHost) {
            // Hanya jika statusnya WAITING atau IN_GAME
            if (status == 'WAITING' || status == 'IN_GAME') {
              // Set state untuk menampilkan info lobby di halaman BuatLobby
              setState(() {
                _isLobbyCreated = true;
                lobbyCode = _lastLobbyCode;
                _actualHostId = hostId;
              });

              // Jika status sudah IN_GAME (Game sudah jalan), Host langsung me-rejoin Leaderboard
              if (status == 'IN_GAME' && mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          LeaderboardPage(lobbyCode: _lastLobbyCode!)),
                );
                // Langsung return true karena sudah dinavigasi
                return true;
              }

              // Jika status WAITING, biarkan tetap di BuatLobbyPage (tombol START aktif)
              return true;
            }
          }

          // JIKA BUKAN HOST, KITA TIDAK LAKUKAN APA-APA DI HALAMAN INI.
          // Non-Host harus bergabung melalui halaman 'Gabung Lobby'.
        }
      } catch (e) {
        // Abaikan error
      }
    }
    return false;
  }

  Future<void> _createLobbyWithTeams() async {
    if (_localUserId == null) {
      _showSnackBar('Gagal mendapatkan User ID. Coba lagi.');
      return;
    }

    setState(() {
      _isLobbyCreated = false;
      lobbyCode = 'Membuat kode...';
    });

    try {
      final newCode = await _db.generateLobbyCode();
      await _db.createLobby(newCode, hostId: _localUserId);

      // --- PANGGIL FUNGSI DATABASE BARU DENGAN PARAMETER 'order' ---
      for (int i = 1; i <= _selectedTeamCount; i++) {
        // Kirimkan i sebagai urutan tim.
        await _db.addTeamToLobby(newCode, 'Tim $i', order: i);
      }
      // -----------------------------------------------------------------

      // Simpan kode lobby di shared preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_lobby_code', newCode);
      // Hapus token peserta jika ada
      await prefs.remove('last_team_id');
      await prefs.remove('last_player_id');

      setState(() {
        _isLobbyCreated = true;
        lobbyCode = newCode;
        _lastLobbyCode = newCode;
        _actualHostId = _localUserId;
      });
    } catch (e) {
      _showSnackBar('Gagal membuat lobi: ${e.toString()}');
      setState(() {
        _isLobbyCreated = false;
        lobbyCode = 'Terjadi kesalahan';
      });
    }
  }

  void _showTeamSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pilih Jumlah Tim'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih jumlah tim yang akan berpartisipasi:'),
              const SizedBox(height: 10),
              StatefulBuilder(
                builder: (context, setStateSB) {
                  return Container(
                    width: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: DropdownButton<int>(
                      value: _selectedTeamCount,
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: List.generate(
                        10,
                        (index) => DropdownMenuItem(
                          value: index + 1,
                          child: Text('${index + 1} Tim'),
                        ),
                      ),
                      onChanged: (value) {
                        setStateSB(() {
                          _selectedTeamCount = value!;
                        });
                      },
                    ),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                // Hanya pop jika belum ada lobby yang dibuat/rejoin
                if (!_isLobbyCreated) {
                  Navigator.pop(
                      context); // Kembali ke halaman sebelumnya (Home/Landing)
                }
              },
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _createLobbyWithTeams();
              },
              child: const Text('Buat Lobby'),
            ),
          ],
        );
      },
    );
  }

  // BARU: Fungsi untuk menghapus data host lokal dan navigasi kembali
  Future<void> _logoutHost() async {
    final prefs = await SharedPreferences.getInstance();
    // Hapus kode lobby Host
    await prefs.remove('last_lobby_code');

    // Opsional: Anda bisa menghapus lobby di Firebase jika ingin
    // Tapi untuk kasus 'rejoin' ini, kita biarkan saja lobby tetap ada di DB

    if (mounted) {
      Navigator.pop(context); // Kembali ke halaman Home/Landing
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // 0. CEK SESI PESERTA AKTIF DULU
      final isParticipant = await _checkParticipantSession();
      if (isParticipant) {
        return; // Jika Peserta aktif, hentikan inisialisasi Host
      }

      // 1. Dapatkan atau buat ID host lokal
      await _getOrCreateLocalUserId();

      // 2. Cek apakah ada lobi lama yang bisa di-rejoin (sebagai Host)
      final canRejoin = await _checkLastLobby();

      // 3. Jika tidak bisa rejoin atau tidak ada lobby, tampilkan dialog
      if (!canRejoin) {
        _showTeamSelectionDialog();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan apakah perangkat ini adalah host
    final isHost = _localUserId != null && _actualHostId == _localUserId;

    // Tentukan teks tombol START dan warnanya
    Color startButtonColor = Colors.grey;
    String startButtonText = 'START GAME';
    bool startButtonEnabled = false;

    if (_isLobbyCreated && lobbyCode != null) {
      if (isHost) {
        startButtonColor = Colors.green[700]!;
        startButtonEnabled = true;
      } else {
        // Perangkat ini sedang me-rejoin lobby orang lain
        startButtonText = 'Menunggu Host...';
        startButtonColor = Colors.orange;
        startButtonEnabled = false;
      }
    }

    // --- MULAI PERBAIKAN TAMPILAN ---
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue[700],
        elevation: 4,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        title: const Text(
          'LOBBY PANITIA',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (!_isLobbyCreated)
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'KEMBALI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
          if (_isLobbyCreated && isHost)
            TextButton.icon(
              onPressed: _logoutHost,
              icon: const Icon(Icons.exit_to_app, color: Colors.white),
              label: const Text(
                'KELUAR',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: Center(
        child: Column(
          children: [
            // Header Info Lobby (Tetap Sama)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
              color: Colors.blue[50],
              width: double.infinity,
              child: Column(
                children: [
                  const Text(
                    'KODE LOBBY',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  Text(
                    lobbyCode ?? 'Membuat kode...',
                    style: TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.w900,
                      color: Colors.red[700],
                      letterSpacing: 5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isHost
                        ? 'Anda adalah HOST'
                        : 'Anda terhubung sebagai Peninjau',
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      color: isHost ? Colors.green[800] : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),

            // --- PERBAIKAN DAFTAR TIM: Lebih Jelas Menggunakan Card & ListTile ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DAFTAR TIM',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87),
                    ),
                    const Divider(color: Colors.blueAccent),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        padding: const EdgeInsets.all(10),
                        child: !_isLobbyCreated
                            ? Center(
                                child:
                                    Text(lobbyCode ?? 'Mencari Lobby Lama...'))
                            : StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance
                                    .collection('lobbies')
                                    .doc(lobbyCode!)
                                    .collection('teams')
                                    .snapshots(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text('Error: ${snapshot.error}'));
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return const Center(
                                        child: Text(
                                            'Belum ada tim yang dibuat. Silakan buat lobby.'));
                                  }

                                  final teams = snapshot.data!.docs;
                                  teams.sort((a, b) {
                                    final aName = a['team_name'] as String;
                                    final bName = b['team_name'] as String;
                                    final aNum =
                                        int.tryParse(aName.split(' ')[1]) ?? 0;
                                    final bNum =
                                        int.tryParse(bName.split(' ')[1]) ?? 0;
                                    return aNum.compareTo(bNum);
                                  });

                                  return ListView.builder(
                                    itemCount: teams.length,
                                    itemBuilder: (context, index) {
                                      final teamDoc = teams[index];
                                      final teamName =
                                          teamDoc['team_name'] as String;
                                      return StreamBuilder<QuerySnapshot>(
                                        stream: _db.getPlayersInTeam(
                                            lobbyCode!, teamDoc.id),
                                        builder: (context, playerSnapshot) {
                                          if (playerSnapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Card(
                                              elevation: 1,
                                              margin: const EdgeInsets.only(
                                                  bottom: 8),
                                              child: ListTile(
                                                leading: CircleAvatar(
                                                    backgroundColor:
                                                        Colors.blueGrey,
                                                    child: Text('${index + 1}',
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold))),
                                                title: Text(teamName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                subtitle: const Text(
                                                    'Memuat pemain...',
                                                    style: TextStyle(
                                                        fontStyle:
                                                            FontStyle.italic)),
                                              ),
                                            );
                                          }

                                          final playerDocs =
                                              playerSnapshot.data!.docs;
                                          String playerText;
                                          Color playerTextColor;
                                          Icon? trailingIcon;

                                          if (playerDocs.isEmpty) {
                                            playerText =
                                                'Menunggu pemain bergabung...';
                                            playerTextColor = Colors.redAccent;
                                            trailingIcon = const Icon(
                                                Icons.warning,
                                                color: Colors.redAccent);
                                          } else {
                                            final playerNames = playerDocs
                                                .map((doc) =>
                                                    (doc.data() as Map<String,
                                                                dynamic>)[
                                                            'player_name']
                                                        as String? ??
                                                    'Pemain')
                                                .join(', ');
                                            playerText = 'Pemain: $playerNames';
                                            playerTextColor = Colors.black87;
                                            trailingIcon = const Icon(
                                                Icons.check_circle,
                                                color: Colors.green);
                                          }

                                          // Widget Card diperluas dan di desain modern
                                          return Card(
                                            elevation: 4, // Card lebih menonjol
                                            margin: const EdgeInsets.only(
                                                bottom: 12),
                                            shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: BorderSide(
                                                    color: playerDocs.isEmpty
                                                        ? Colors.red
                                                            .withOpacity(0.5)
                                                        : Colors.green
                                                            .withOpacity(0.5),
                                                    width: 1)),
                                            child: ListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 8,
                                                      horizontal: 16),
                                              leading: CircleAvatar(
                                                radius:
                                                    24, // Avatar lebih besar
                                                backgroundColor:
                                                    Colors.blueAccent,
                                                child: Text('${index + 1}',
                                                    style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18)),
                                              ),
                                              title: Text(
                                                teamName,
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize:
                                                        20, // Nama tim lebih besar
                                                    color: Colors.blueGrey),
                                              ),
                                              subtitle: Text(
                                                playerText,
                                                style: TextStyle(
                                                    color: playerTextColor,
                                                    fontSize: 14,
                                                    fontStyle:
                                                        playerDocs.isEmpty
                                                            ? FontStyle.italic
                                                            : FontStyle.normal),
                                              ),
                                              trailing: trailingIcon,
                                            ),
                                          );
                                        },
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

            // --- PERBAIKAN TOMBOL START: Diperkecil ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(
                  15.0), // Padding dikurangi dari 20 menjadi 15
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: startButtonEnabled
                    ? () {
                        if (_isLobbyCreated && lobbyCode != null) {
                          _db.updateLobbyStatus(lobbyCode!, 'IN_GAME');
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  LeaderboardPage(lobbyCode: lobbyCode!),
                            ),
                          ).then((_) {});
                        }
                      }
                    : null,
                icon: const Icon(Icons.videogame_asset,
                    color: Colors.white,
                    size: 24), // Ukuran ikon dikurangi dari 28 menjadi 24
                label: Text(
                  startButtonText,
                  style: const TextStyle(
                    fontSize: 20, // Ukuran teks dikurangi dari 28 menjadi 20
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: startButtonColor,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50,
                      vertical:
                          15), // Padding vertikal dikurangi dari 20 menjadi 15
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12), // Radius sedikit dikurangi
                  ),
                  elevation: 5, // Shadow dikurangi sedikit
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
