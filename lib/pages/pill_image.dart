import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

/// Screen for capturing an image of the actual medication pill.
class PillImage extends StatefulWidget {
  const PillImage({super.key});

  @override
  State<PillImage> createState() => _PillImageState();
}

/// State management for pill image capture and data passing.
class _PillImageState extends State<PillImage> {
  final Color bgColor = const Color(0xFFF2FBFA);
  final Color textColor = const Color(0xFF5A3B24);
  final Color accentColor = const Color(0xFFFCA048);

  CameraController? _cameraController;
  bool _isProcessing = false;

  String _scannedText = '';
  String _descImagePath = '';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  /// Initializes the camera with predefined settings.
  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();

        await _cameraController!.setFlashMode(FlashMode.off);

        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Camera Error: $e");
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    /// Retrieves arguments passed from the label scanning screen.
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null) {
      if (args is String) {
        _scannedText = args;
      } else if (args is Map) {
        _scannedText = args['text'] ?? '';
        _descImagePath = args['descImagePath'] ?? args['imagePath'] ?? '';
      }
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  /// Captures pill photo and navigates to the confirmation screen.
  Future<void> _takePillPicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;

    setState(() => _isProcessing = true);

    try {
      final XFile imageFile = await _cameraController!.takePicture();

      setState(() => _isProcessing = false);

      if (mounted) {
        Navigator.pushNamed(
          context,
          '/pill_confirmation',
          arguments: {
            'text': _scannedText,
            'descImagePath': _descImagePath,
            'pillImagePath': imageFile.path,
          },
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      debugPrint("Error taking pill picture: $e");
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
              padding: const EdgeInsets.only(top: 10, right: 20, left: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: textColor,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  IconButton(
                    icon: Icon(Icons.alarm, color: textColor, size: 28),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/time_setting'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Take a Pill Image',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Please put the pill inside the rectangle',
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 40),

                  /// Camera preview interface with a focus rectangle.
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
                          onTap: _takePillPicture,
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

  /// Builds the navigation bar for the application.
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

  /// Helper to create individual navigation icons.
  Widget _navItem(
    BuildContext context,
    IconData icon,
    int index,
    bool isSelected,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == 0)
            Navigator.pushReplacementNamed(context, '/pill_description');
          else if (index == 1)
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
