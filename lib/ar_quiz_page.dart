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

class ARQuizPage extends StatefulWidget {
  final Map<String, dynamic> quizData;
  const ARQuizPage({super.key, required this.quizData});

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

  @override
  void dispose() {
    arSessionManager?.dispose();
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

    // pakai API baru
    this.arSessionManager?.onPlaneOrPointTap = onPlaneTapHandler;
  }

  Future<void> onPlaneTapHandler(List<ARHitTestResult> hitTestResults) async {
    final planeHitTest =
        hitTestResults
            .where((element) => element.type == ARHitTestResultType.plane)
            .cast<ARHitTestResult?>()
            .firstOrNull; // tersedia di Dart 3.x, kalau belum ada -> pakai extension sendiri

    if (planeHitTest != null) {
      for (var node in quizNodes) {
        await arObjectManager?.removeNode(node);
      }
      quizNodes.clear();

      _addQuizContent(planeHitTest.worldTransform);
    }
  }

  void _addQuizContent(vector.Matrix4 transform) async {
    final quizBoardNode = ARNode(
      type: NodeType.localGLTF2,
      uri: 'assets/models/quiz_board.gltf',
      position: vector.Vector3(0.0, 0.0, -1.0),
      scale: vector.Vector3.all(0.1),
    );
    await arObjectManager?.addNode(quizBoardNode);
    quizNodes.add(quizBoardNode);
  }

  void _checkAnswer(String answer) {
    setState(() {
      selectedAnswer = answer;
      isAnswerSubmitted = true;
      if (answer == widget.quizData['answer']) {
        feedbackMessage = '✅ Jawaban Anda benar!';
      } else {
        feedbackMessage =
            '❌ Salah. Jawaban yang benar adalah ${widget.quizData['answer']}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kuis AR', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          ARView(onARViewCreated: onARViewCreated),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  color: const Color.fromRGBO(255, 255, 255, 0.8),
                  child: Column(
                    children: [
                      Text(
                        widget.quizData['question'],
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      ...widget.quizData['options'].map<Widget>((option) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: ElevatedButton(
                            onPressed: () {
                              if (!isAnswerSubmitted) {
                                _checkAnswer(option);
                              }
                            },
                            child: Text(option),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                if (isAnswerSubmitted)
                  Text(
                    feedbackMessage,
                    style: TextStyle(
                      fontSize: 20,
                      color:
                          widget.quizData['answer'] == selectedAnswer
                              ? Colors.green
                              : Colors.red,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
