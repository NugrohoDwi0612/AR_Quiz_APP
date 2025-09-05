import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  Future<void> _checkLobbyAndShowTeams() async {
    final lobbyCode = _lobbyCodeController.text.trim();
    if (lobbyCode.isEmpty) {
      _showSnackBar('Kode lobi tidak boleh kosong.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final lobbySnapshot = await _db.getLobbyData(lobbyCode);
      if (lobbySnapshot.exists) {
        _showTeamSelectionDialog(lobbyCode);
      } else {
        _showSnackBar('Kode lobi tidak ditemukan.');
      }
    } catch (e) {
      _showSnackBar('Terjadi kesalahan: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showTeamSelectionDialog(String lobbyCode) async {
    showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<QuerySnapshot>(
          stream: _db.getLobbyTeams(lobbyCode),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

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
    final TextEditingController nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Masukkan Nama Anda'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              hintText: 'Nama Anda',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final playerName = nameController.text.trim();
                if (playerName.isNotEmpty) {
                  Navigator.pop(dialogContext); // Tutup dialog input nama

                  final playerId =
                      await _db.addPlayerToTeam(lobbyCode, teamId, playerName);

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
                  }
                } else {
                  _showSnackBar('Nama tidak boleh kosong.');
                }
              },
              child: const Text('Gabung'),
            ),
          ],
        );
      },
    );
  }

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
                  style: const TextStyle(
                    fontSize: 30,
                    letterSpacing: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
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
              if (_isLoading)
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
            ],
          ),
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
}
