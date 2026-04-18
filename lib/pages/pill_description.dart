import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Screen for scanning medication labels using the camera and ML Kit.
class PillDescription extends StatefulWidget {
  const PillDescription({super.key});

  @override
  State<PillDescription> createState() => _PillDescriptionState();
}

/// State management for camera preview and text recognition.
class _PillDescriptionState extends State<PillDescription> {
  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color accentColor = const Color(0xFFFCA048);

  CameraController? _cameraController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// Initializes the camera and sets default configurations.
  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
      );
      await _cameraController!.initialize();

      await _cameraController!.setFlashMode(FlashMode.off);

      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// Captures an image and processes it to extract text via ML Kit.
  Future<void> _scanPillLabel() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    setState(() => _isProcessing = true);

    try {
      final XFile image = await _cameraController!.takePicture();

      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.latin,
      );
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      String scannedText = recognizedText.text;
      textRecognizer.close();

      setState(() => _isProcessing = false);

      /// Navigates to the next screen with recognized text and image path.
      if (mounted) {
        Navigator.pushNamed(
          context,
          '/pill_image',
          arguments: {'text': scannedText, 'descImagePath': image.path},
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint("Error reading text: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.alarm, color: textColor, size: 28),
                  onPressed: () =>
                      Navigator.pushNamed(context, '/time_setting'),
                ),
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Add a new description',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Please put the description inside the rectangle',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 40),

                  /// Camera preview widget with visual guide.
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child:
                              (_cameraController != null &&
                                  _cameraController!.value.isInitialized)
                              ? CameraPreview(_cameraController!)
                              : const Center(
                                  child: CircularProgressIndicator(),
                                ),
                        ),
                      ),
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.red, width: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 50),

                  _isProcessing
                      ? const CircularProgressIndicator()
                      : GestureDetector(
                          onTap: _scanPillLabel,
                          child: Container(
                            width: 150,
                            height: 50,
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF5A3B24),
                              size: 30,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  /// Builds the custom bottom navigation bar.
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 80,
      decoration: const BoxDecoration(
        color: Color(0xFF88C5C4),
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(context, Icons.add, 0, true),
          _navItem(context, Icons.medication_outlined, 1, false),
          _navItem(context, Icons.home, 2, false),
          _navItem(context, Icons.menu_book_outlined, 3, false),
          _navItem(context, Icons.person_outline, 4, false),
        ],
      ),
    );
  }

  /// Individual navigation item helper.
  Widget _navItem(
    BuildContext context,
    IconData icon,
    int index,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 1)
            Navigator.pushReplacementNamed(context, '/stock');
          else if (index == 2)
            Navigator.pushReplacementNamed(context, '/home');
          else if (index == 3)
            Navigator.pushReplacementNamed(context, '/history');
          else if (index == 4)
            Navigator.pushNamed(context, '/profile');
        },
        child: Container(
          color: Colors.transparent,
          height: 80,
          child: Center(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFCA048)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF5A3B24), size: 32),
            ),
          ),
        ),
      ),
    );
  }
}
