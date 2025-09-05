import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FirebaseDB {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  static const String _chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890';

  Future<String> generateLobbyCode() async {
    String code;
    bool isUnique = false;

    do {
      code = _generateRandomCode(5);
      final docSnapshot =
          await _firestore.collection('lobbies').doc(code).get();
      isUnique = !docSnapshot.exists;
    } while (!isUnique);

    return code;
  }

  String _generateRandomCode(int length) {
    return String.fromCharCodes(Iterable.generate(
      length,
      (_) => _chars.codeUnitAt(_random.nextInt(_chars.length)),
    ));
  }

  Future<void> createLobby(String lobbyCode) async {
    await _firestore.collection('lobbies').doc(lobbyCode).set({
      'status': 'WAITING',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<DocumentReference> addTeamToLobby(
      String lobbyCode, String teamName) async {
    return await _firestore
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('teams')
        .add({
      'team_name': teamName,
      'is_joined': false,
      'score': 0,
    });
  }

  Stream<QuerySnapshot> getLobbyTeams(String lobbyCode) {
    return _firestore
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('teams')
        .orderBy('team_name')
        .snapshots();
  }

  Future<void> updateTeam(
      String lobbyCode, String teamId, Map<String, dynamic> data) async {
    await _firestore
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('teams')
        .doc(teamId)
        .update(data);
  }

  Future<String> addPlayerToTeam(
      String lobbyCode, String teamId, String playerName) async {
    final teamDoc = await _firestore
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('teams')
        .doc(teamId)
        .get();
    final teamName = teamDoc.data()?['team_name'] as String? ?? 'N/A';

    final playerDocRef = await _firestore
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .add({
      'player_name': playerName,
      'score': 0,
      'joined_at': FieldValue.serverTimestamp(),
      'lobbyCode': lobbyCode,
      'team_name': teamName,
    });

    await updateTeam(lobbyCode, teamId, {'is_joined': true});
    return playerDocRef.id;
  }

  Stream<QuerySnapshot> getPlayersInTeam(String lobbyCode, String teamId) {
    return _firestore
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .snapshots();
  }

  Future<void> addQuizQuestion({
    required String qrCodeId,
    required String questionText,
    required List<String> options,
    required String correctAnswer,
    required int points,
  }) async {
    await _firestore.collection('qrcodes').doc(qrCodeId).set({
      'question_text': questionText,
      'options': options,
      'correct_answer': correctAnswer,
      'points': points,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<QuerySnapshot> getQuizQuestions() async {
    return await _firestore.collection('qrcodes').get();
  }

  Future<void> updateLobbyStatus(String lobbyCode, String newStatus) async {
    await _firestore.collection('lobbies').doc(lobbyCode).update({
      'status': newStatus,
    });
  }

  Future<DocumentSnapshot> getLobbyData(String lobbyCode) async {
    return await _firestore.collection('lobbies').doc(lobbyCode).get();
  }

  // Fungsi Perbarui skor pemain dan tim secara bersamaan
  Future<void> updatePlayerAndTeamScore({
    required String lobbyCode,
    required String teamId,
    required String playerId,
    required int pointsToAdd,
  }) async {
    final playerRef = _firestore
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .doc(playerId);

    final teamRef = _firestore
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('teams')
        .doc(teamId);

    final batch = _firestore.batch();

    // Tambahkan poin ke skor pemain
    batch.update(playerRef, {'score': FieldValue.increment(pointsToAdd)});

    // Tambahkan poin yang sama ke skor total tim
    batch.update(teamRef, {'score': FieldValue.increment(pointsToAdd)});

    await batch.commit();
  }

  Future<void> addScannedQuiz({
    required String lobbyCode,
    required String teamId,
    required String playerId,
    required String quizId,
  }) async {
    await _firestore
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .doc(playerId)
        .collection('scanned_qrs')
        .doc(quizId)
        .set({
      'scanned_at': FieldValue.serverTimestamp(),
    });
  }

// Fungsi ini untuk memeriksa apakah kuis sudah pernah di-scan
  Future<bool> hasPlayerScannedQuiz({
    required String lobbyCode,
    required String teamId,
    required String playerId,
    required String quizId,
  }) async {
    final docSnapshot = await _firestore
        .collection('lobbies')
        .doc(lobbyCode)
        .collection('teams')
        .doc(teamId)
        .collection('players')
        .doc(playerId)
        .collection('scanned_qrs')
        .doc(quizId)
        .get();

    return docSnapshot.exists;
  }
}
