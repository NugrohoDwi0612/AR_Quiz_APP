import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <<< WAJIB DIIMPOR
import 'firebase_db.dart';
import 'lobby_peserta_page.dart';


class PesertaPage extends StatefulWidget {
  const PesertaPage({super.key});

  @override
  State<PesertaPage> createState() => _PesertaPageState();
}

class _PesertaPageState extends State<PesertaPage> {
  final FirebaseDB _db = FirebaseDB();
  final TextEditingController _lobbyCodeController = TextEditingController();
  bool _isLoading = false;
  String? _localUserId; // <<< VARIABEL BARU UNTUK MENYIMPAN ID HOST LOKAL

  @override
  void initState() {
    super.initState();
    _checkSavedLobbySession(); // <<< Panggil fungsi pengecekan sesi
    _getOrCreateLocalUserId(); // Panggil ini juga, seperti yang kita tambahkan sebelumnya
  }

  Future<void> _checkSavedLobbySession() async {
    final prefs = await SharedPreferences.getInstance();
    // Gunakan String? untuk memungkinkan pengecekan null yang aman
    final String? lobbyCode = prefs.getString('last_lobby_code');
    final String? teamId = prefs.getString('last_team_id');
    final String? playerId = prefs.getString('last_player_id');

    // 1. Cek apakah ada sesi lokal yang tersimpan
    if (lobbyCode != null && teamId != null && playerId != null) {
      // 2. VERIFIKASI: Cek status Lobi di Database
      // Asumsi _db.getLobbyData mengembalikan Map<String, dynamic>?
      final lobbyData = await _db.getLobbyData(lobbyCode);

      // Cek apakah lobi masih ada (tidak null) DAN statusnya 'WAITING' ATAU 'IN_GAME'
      // *** KRITIS: Penggunaan tanda kurung untuk prioritas operator ***
      final bool isLobbyActive = lobbyData != null &&
          (lobbyData['status'] == 'WAITING' ||
              lobbyData['status'] == 'IN_GAME');

      if (isLobbyActive) {
        // Jika lobi masih aktif, navigasikan kembali ke lobi
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => LobbyPesertaPage(
                lobbyCode: lobbyCode,
                teamId: teamId,
                playerId: playerId,
              ),
            ),
          );
          return; // Hentikan eksekusi
        }
      } else {
        // 3. JIKA LOBI TIDAK VALID/TUTUP/GANTI, HAPUS SESI LAMA
        await prefs.remove('last_lobby_code');
        await prefs.remove('last_team_id');
        await prefs.remove('last_player_id');

        // Tampilkan pesan
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Sesi lobi lama sudah tidak aktif. Silakan masukkan kode baru.',
              ),
            ),
          );
        }
      }
    }
    // Jika tidak ada sesi atau sesi dihapus, biarkan tampilan PesertaPage (input kode) dimuat.
  }

  // <<< FUNGSI BARU: Mendapatkan/Membuat User ID Lokal (Penting untuk Identifikasi Host)
  Future<void> _getOrCreateLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('local_user_id');

    if (storedId == null) {
      // Membuat ID unik sederhana
      storedId = DateTime.now().millisecondsSinceEpoch.toString() +
          (DateTime.now().microsecondsSinceEpoch % 1000).toString();
      await prefs.setString('local_user_id', storedId);
    }

    if (mounted) {
      setState(() {
        _localUserId = storedId;
      });
    }
  }
  // >>> AKHIR FUNGSI BARU

  void _showSnackBar(String message, {Color color = Colors.red}) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
        ),
      );
    }
  }

  Future<void> _checkLobbyAndShowTeams() async {
    final lobbyCode = _lobbyCodeController.text.trim().toUpperCase();

    if (lobbyCode.isEmpty) {
      _showSnackBar('Kode lobi tidak boleh kosong.');
      return;
    }
    if (_localUserId == null) {
      _showSnackBar('ID perangkat belum dimuat. Coba lagi.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final lobbySnapshot = await _db.getLobbyData(lobbyCode);

      if (!lobbySnapshot.exists) {
        _showSnackBar('Kode lobi tidak ditemukan.');
        return;
      }

      final hostId = lobbySnapshot.get('host_id');

      // <<< LOGIKA BATASAN PANITIA/HOST (PENTING)
      if (hostId == _localUserId) {
        _showSnackBar(
          'Akses Ditolak: Perangkat ini adalah **Host/Panitia** dari lobi "$lobbyCode". Harap gunakan menu Panitia.',
          color: Colors.orange,
        );
        return; // Menghentikan proses gabung peserta
      }
      // >>> AKHIR LOGIKA BATASAN

      // Jika lolos pengecekan (bukan host), lanjutkan ke dialog pemilihan tim
      _showTeamSelectionDialog(lobbyCode);
    } on FirebaseException catch (e) {
      _showSnackBar('Gagal memverifikasi lobi: ${e.message}');
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showTeamSelectionDialog(String lobbyCode) async {
    // ... (Logika _showTeamSelectionDialog TIDAK DIUBAH)
    // Tanda: Pastikan Anda juga menyimpan last_lobby_code di SharedPreferences
    // saat pemain berhasil bergabung setelah _showNameInputDialog.

    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _db.getLobbyTeams(lobbyCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            // ... (Kode error dan lobi kosong)
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Error'),
                content: Text('Terjadi kesalahan: ${snapshot.error}'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  )
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return AlertDialog(
                title: const Text('Lobi Kosong'),
                content:
                    const Text('Belum ada tim yang dibuat untuk lobi ini.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  )
                ],
              );
            }

            final teams = snapshot.data!.docs;

            return AlertDialog(
              title: const Text('Pilih Tim Anda'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: teams.map((teamDoc) {
                    final teamName = teamDoc['team_name'] as String;
                    return ListTile(
                      title: Text(teamName),
                      onTap: () {
                        Navigator.pop(context);
                        _showNameInputDialog(lobbyCode, teamDoc.id);
                      },
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showNameInputDialog(String lobbyCode, String teamId) async {
    final nameController = TextEditingController();
    final dialogContext = context; // Simpan konteks untuk dialog

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Masukkan Nama Pemain'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: "Nama Anda"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Gabung'),
              onPressed: () async {
                final playerName = nameController.text.trim();

                if (playerName.isNotEmpty) {
                  Navigator.pop(context); // Tutup dialog input nama

                  // --- 1. DAPATKAN playerId DAHULU DARI DATABASE ---
                  try {
                    final playerId = await _db.addPlayerToTeam(
                      lobbyCode,
                      teamId,
                      playerName,
                      _localUserId,
                    );

                    if (playerId.isNotEmpty) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setString('last_lobby_code', lobbyCode);
                      await prefs.setString('last_team_id', teamId);
                      await prefs.setString('last_player_id', playerId);

                      // --- 3. NAVIGASI KE LOBBY PESERTA ---
                      if (mounted) {
                        Navigator.pushReplacement(
                          dialogContext, // Gunakan dialogContext atau context
                          MaterialPageRoute(
                            builder: (ctx) => LobbyPesertaPage(
                              lobbyCode: lobbyCode,
                              teamId: teamId,
                              playerId: playerId,
                            ),
                          ),
                        );
                      }
                    } else {
                      // Handle jika addPlayerToTeam gagal mendapatkan ID
                      _showSnackBar('Gagal bergabung. ID pemain tidak valid.');
                    }
                  } catch (e) {
                    // Handle error Firebase/DB
                    _showSnackBar('Gagal bergabung: $e');
                  }
                } else {
                  // Nama kosong, tidak perlu menutup dialog, hanya tampilkan SnackBar
                  _showSnackBar('Nama tidak boleh kosong.');
                }
              },
            ),
          ],
        );
      },
    );
  }

// // Pastikan fungsi helper ini ada:
//   void _showSnackBar(String message) {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)),
//       );
//     }
//   }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset('assets/images/logo.png', width: 100),
              const SizedBox(height: 20),
              const Text(
                'PESERTA',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 50),
              const Text(
                'Masukkan Kode Lobby',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              Container(
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
                child: TextField(
                  controller: _lobbyCodeController,
                  textAlign: TextAlign.center,
                  maxLength: 5, // Opsional: Batasi panjang kode lobi
                  style: const TextStyle(
                    fontSize: 30,
                    letterSpacing: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '', // Menghilangkan penghitung karakter
                    hintText: '----',
                    hintStyle: TextStyle(
                      fontSize: 30,
                      letterSpacing: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // Pastikan tombol Gabung dinonaktifkan jika ID lokal belum dimuat
              if (_isLoading || _localUserId == null)
                const CircularProgressIndicator()
              else
                _buildCustomButton(
                  context,
                  'Gabung',
                  _checkLobbyAndShowTeams,
                ),
              const SizedBox(height: 20),
              _buildCustomButton(
                context,
                'Kembali',
                () => Navigator.pop(context),
              ),
              // Tampilkan ID perangkat untuk debugging
              if (_localUserId != null)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text('ID Perangkat (Debug): $_localUserId',
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton(
      BuildContext context, String text, VoidCallback onPressed) {
    // ... (Fungsi _buildCustomButton tidak diubah)
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
}
