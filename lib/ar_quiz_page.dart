import 'package:flutter/material.dart';
import 'package:ar_flutter_plugin/ar_flutter_plugin.dart';
import 'package:ar_flutter_plugin/datatypes/hittest_result_types.dart';
import 'package:ar_flutter_plugin/datatypes/node_types.dart';
import 'package:ar_flutter_plugin/managers/ar_session_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_object_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_anchor_manager.dart';
import 'package:ar_flutter_plugin/managers/ar_location_manager.dart';
import 'package:ar_flutter_plugin/models/ar_hittest_result.dart';
import 'package:ar_flutter_plugin/models/ar_node.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:ar_quiz_app/firebase_db.dart';

const bool isArEnabled = true;

class ARQuizPage extends StatefulWidget {
  final String lobbyCode;
  final String teamId;
  final String playerId;
  final int initialScore;

  const ARQuizPage({
    super.key,
    required this.lobbyCode,
    required this.teamId,
    required this.playerId,
    required this.initialScore,
  });

  @override
  State<ARQuizPage> createState() => _ARQuizPageState();
}

class _ARQuizPageState extends State<ARQuizPage> {
  ARSessionManager? arSessionManager;
  ARObjectManager? arObjectManager;
  ARAnchorManager? arAnchorManager;
  List<ARNode> quizNodes = [];
  String? selectedAnswer;
  bool isAnswerSubmitted = false;
  String feedbackMessage = '';
  Map<String, dynamic>? activeQuizData;
  String? activeQuizId;
  late final DocumentReference _playerScoreRef;
  late final FirebaseDB _firebaseDB;
  QRViewController? _qrViewController;
  final GlobalKey _qrKey = GlobalKey(debugLabel: 'QR');
  bool isScanning = true;

  @override
  void initState() {
    super.initState();
    _firebaseDB = FirebaseDB();
    _playerScoreRef = FirebaseFirestore.instance
        .collection('lobbies')
        .doc(widget.lobbyCode)
        .collection('teams')
        .doc(widget.teamId)
        .collection('players')
        .doc(widget.playerId);
  }

  @override
  void dispose() {
    if (isArEnabled) {
      arSessionManager?.dispose();
    }
    _qrViewController?.dispose();
    super.dispose();
  }

  void onARViewCreated(
    ARSessionManager arSessionManager,
    ARObjectManager arObjectManager,
    ARAnchorManager arAnchorManager,
    ARLocationManager arLocationManager,
  ) {
    this.arSessionManager = arSessionManager;
    this.arObjectManager = arObjectManager;
    this.arAnchorManager = arAnchorManager;

    this.arSessionManager?.onInitialize(
          showFeaturePoints: false,
          showPlanes: true,
          showWorldOrigin: true,
          handleTaps: true,
        );
    this.arObjectManager?.onInitialize();
    this.arSessionManager?.onPlaneOrPointTap = onPlaneTapHandler;
  }

  Future<void> onPlaneTapHandler(List<ARHitTestResult> hitTestResults) async {
    final planeHitTest = hitTestResults
        .where((element) => element.type == ARHitTestResultType.plane)
        .cast<ARHitTestResult?>()
        .firstOrNull;

    if (planeHitTest != null) {
      _addQuizContent(planeHitTest.worldTransform);
    }
  }

  void _addQuizContent(vector.Matrix4 transform) async {
    final quizBoardNode = ARNode(
      type: NodeType.localGLTF2,
      uri: 'assets/models/quiz_board.gltf',
      position: vector.Vector3(0.0, 0.0, -1.0),
      scale: vector.Vector3.all(0.2),
      transformation: transform,
    );
    await arObjectManager?.addNode(quizBoardNode);
    quizNodes.add(quizBoardNode);
  }

  void _onQRViewCreated(QRViewController controller) {
    _qrViewController = controller;
    _qrViewController?.scannedDataStream.listen((scanData) {
      _qrViewController?.pauseCamera();
      if (scanData.code != null) {
        _loadQuizFromQR(scanData.code!);
      } else {
        setState(() {
          feedbackMessage = 'Kode QR tidak valid.';
          isScanning = false;
        });
      }
    });
  }

  Future<void> _loadQuizFromQR(String quizId) async {
    setState(() {
      isScanning = false;
      feedbackMessage = 'Memuat kuis...';
    });

    try {
      // Pengecekan riwayat pemindaian
      final hasScanned = await _firebaseDB.hasPlayerScannedQuiz(
        lobbyCode: widget.lobbyCode,
        teamId: widget.teamId,
        playerId: widget.playerId,
        quizId: quizId,
      );

      if (hasScanned) {
        setState(() {
          feedbackMessage = 'Anda sudah menyelesaikan kuis ini.';
        });
        await Future.delayed(const Duration(seconds: 3));
        _closeQuiz();
        return;
      }

      final docSnapshot = await FirebaseFirestore.instance
          .collection('qrcodes')
          .doc(quizId)
          .get();

      if (docSnapshot.exists) {
        setState(() {
          activeQuizData = docSnapshot.data();
          activeQuizId = quizId;
          selectedAnswer = null;
          isAnswerSubmitted = false;
          feedbackMessage = '';
          quizNodes.clear();
        });
      } else {
        setState(() {
          feedbackMessage = 'Soal kuis tidak ditemukan.';
        });
      }
    } catch (e) {
      setState(() {
        feedbackMessage = 'Gagal memuat kuis: ${e.toString()}';
      });
    }
  }

  void _checkAnswer(String answer) async {
    if (activeQuizData == null || isAnswerSubmitted) return;

    setState(() {
      selectedAnswer = answer;
      isAnswerSubmitted = true;
    });

    if (answer == activeQuizData!['correct_answer']) {
      await _firebaseDB.updatePlayerAndTeamScore(
        lobbyCode: widget.lobbyCode,
        teamId: widget.teamId,
        playerId: widget.playerId,
        pointsToAdd: activeQuizData!['points'] as int,
      );

      if (activeQuizId != null) {
        await _firebaseDB.addScannedQuiz(
          lobbyCode: widget.lobbyCode,
          teamId: widget.teamId,
          playerId: widget.playerId,
          quizId: activeQuizId!,
        );
      }

      setState(() {
        feedbackMessage = '✅ Jawaban Anda benar!';
      });
    } else {
      setState(() {
        feedbackMessage =
            '❌ Salah. Jawaban yang benar adalah ${activeQuizData!['correct_answer']}';
      });
    }
  }

  void _closeQuiz() async {
    if (arObjectManager != null) {
      for (var node in quizNodes) {
        await arObjectManager?.removeNode(node);
      }
    }

    if (isArEnabled) {
      arSessionManager?.dispose();
      arSessionManager = null;
    }

    setState(() {
      activeQuizData = null;
      activeQuizId = null;
      selectedAnswer = null;
      isAnswerSubmitted = false;
      feedbackMessage = '';
      quizNodes.clear();
      isScanning = true;
    });

    _qrViewController?.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          if (isScanning)
            QRView(
              key: _qrKey,
              onQRViewCreated: _onQRViewCreated,
              overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: 250,
              ),
            )
          else if (isArEnabled)
            ARView(onARViewCreated: onARViewCreated)
          else
            Container(color: Colors.black),
          if (activeQuizData != null && !isScanning)
            Positioned.fill(
              child: Container(
                color: const Color.fromRGBO(0, 0, 0, 0.6),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: const [
                        BoxShadow(
                          color: Color.fromRGBO(0, 0, 0, 0.2),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          activeQuizData!['question_text'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ...activeQuizData!['options'].map<Widget>((option) {
                          final isCorrect =
                              option == activeQuizData!['correct_answer'];
                          final isSelected = option == selectedAnswer;
                          Color buttonColor = Colors.blue;
                          if (isAnswerSubmitted) {
                            if (isSelected && isCorrect) {
                              buttonColor = Colors.green;
                            } else if (isSelected && !isCorrect) {
                              buttonColor = Colors.red;
                            } else if (isCorrect) {
                              buttonColor = Colors.grey;
                            }
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ElevatedButton(
                              onPressed: isAnswerSubmitted
                                  ? null
                                  : () => _checkAnswer(option),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: Text(
                                option,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 15),
                        if (isAnswerSubmitted)
                          Text(
                            feedbackMessage,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: selectedAnswer ==
                                      activeQuizData!['correct_answer']
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _closeQuiz,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Tutup Kuis',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (feedbackMessage.isNotEmpty &&
              activeQuizData == null &&
              !isScanning)
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(0, 0, 0, 0.7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    feedbackMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SafeArea(
                child: Row(
                  children: [
                    Image.asset('assets/images/logo.png', width: 80),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Kembali',
                            style: TextStyle(color: Colors.red, fontSize: 18),
                          ),
                        ),
                        StreamBuilder<DocumentSnapshot>(
                          stream: _playerScoreRef.snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }
                            if (snapshot.hasError) {
                              return Text('Error: ${snapshot.error}');
                            }
                            final score = (snapshot.data!.data()
                                    as Map<String, dynamic>?)?['score'] ??
                                0;
                            return Text(
                              'Score: $score',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
