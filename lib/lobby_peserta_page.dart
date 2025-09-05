import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('lobbies')
                .doc(widget.lobbyCode)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Lobi tidak ditemukan.'));
              }

              final lobbyData = snapshot.data!.data() as Map<String, dynamic>;
              final lobbyStatus = lobbyData['status'] as String?;

              // Jika status IN_GAME, langsung navigasi
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

              return Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Image.asset('assets/images/logo.png', width: 80),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Kembali',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 50),
                    const Text(
                      'LOBBY',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'KODE LOBBY',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      widget.lobbyCode,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 30),
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
                        child: StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('lobbies')
                              .doc(widget.lobbyCode)
                              .collection('teams')
                              .orderBy('team_name')
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
                            return ListView.builder(
                              itemCount: teams.length,
                              itemBuilder: (context, index) {
                                final teamDoc = teams[index];
                                final teamName = teamDoc['team_name'] as String;
                                return StreamBuilder<QuerySnapshot>(
                                  stream: _db.getPlayersInTeam(
                                      widget.lobbyCode, teamDoc.id),
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
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
