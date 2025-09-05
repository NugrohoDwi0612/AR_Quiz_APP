import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_db.dart';
import 'leaderboard_page.dart';

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

  Future<void> _createLobbyWithTeams() async {
    setState(() {
      _isLobbyCreated = false;
      lobbyCode = 'Membuat kode...';
    });

    try {
      final newCode = await _db.generateLobbyCode();
      await _db.createLobby(newCode);

      for (int i = 1; i <= _selectedTeamCount; i++) {
        await _db.addTeamToLobby(newCode, 'Tim $i');
      }

      setState(() {
        _isLobbyCreated = true;
        lobbyCode = newCode;
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
                Navigator.pop(context);
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isLobbyCreated) {
        _showTeamSelectionDialog();
      }
    });
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'BUAT LOBBY',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'KODE LOBBY',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                lobbyCode ?? 'Membuat kode...',
                style: const TextStyle(
                  fontSize: 50,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: !_isLobbyCreated
                      ? const Center(child: CircularProgressIndicator())
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
                                  child: Text('Error: ${snapshot.error}'));
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const Center(
                                  child: Text('Belum ada tim yang dibuat.'));
                            }

                            final teams = snapshot.data!.docs;

                            // Pengurutan manual di sini
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
                                final teamName = teamDoc['team_name'] as String;
                                return StreamBuilder<QuerySnapshot>(
                                  stream: _db.getPlayersInTeam(
                                      lobbyCode!, teamDoc.id),
                                  builder: (context, playerSnapshot) {
                                    if (playerSnapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8.0),
                                        child: Text(
                                          '${index + 1}. $teamName - Memuat pemain...',
                                          style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.black),
                                        ),
                                      );
                                    }
                                    final playerDocs =
                                        playerSnapshot.data!.docs;
                                    String playerText;
                                    if (playerDocs.isEmpty) {
                                      playerText = ' - Menunggu pemain...';
                                    } else {
                                      final playerNames = playerDocs
                                          .map((doc) =>
                                              (doc.data() as Map<String,
                                                      dynamic>)['player_name']
                                                  as String? ??
                                              'Pemain')
                                          .join(', ');
                                      playerText =
                                          ' - $playerNames bergabung kedalam lobby';
                                    }
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8.0),
                                      child: RichText(
                                        text: TextSpan(
                                          style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.black),
                                          children: [
                                            TextSpan(text: '${index + 1}. '),
                                            TextSpan(
                                              text: teamName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.red),
                                            ),
                                            TextSpan(
                                              text: playerText,
                                              style: const TextStyle(
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
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
              const SizedBox(height: 20),
              ElevatedButton.icon(
                // Klik tombol START status lobby menjadi IN_GAME
                onPressed: () {
                  if (_isLobbyCreated && lobbyCode != null) {
                    _db.updateLobbyStatus(lobbyCode!, 'IN_GAME');
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            LeaderboardPage(lobbyCode: lobbyCode!),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text(
                  'START',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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
