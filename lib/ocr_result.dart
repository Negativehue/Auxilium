import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'summary_and_reviewer_generation.dart';


class OCRResultScreen extends StatefulWidget {
  final String initialText;

  const OCRResultScreen({Key? key, required this.initialText}) : super(key: key);

  @override
  _OCRResultScreenState createState() => _OCRResultScreenState();
}

class _OCRResultScreenState extends State<OCRResultScreen> {
  String _displayedText = '';
  File? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer();
  final TextEditingController _textController = TextEditingController();

  // Undo/Redo stacks
  final List<String> _undoStack = [];
  final List<String> _redoStack = [];

  @override
  void initState() {
    super.initState();
    _displayedText = widget.initialText;
    _textController.text = _displayedText;
    _saveToUndoStack();
  }

  @override
  void dispose() {
    _textRecognizer.close();
    _textController.dispose();
    super.dispose();
  }

  void _saveToUndoStack() {
    if (_undoStack.isEmpty || _undoStack.last != _textController.text) {
      _undoStack.add(_textController.text);
      _redoStack.clear(); // Clear redo stack when a new change is made
    }
  }

  void _undo() {
    if (_undoStack.length > 1) {
      _redoStack.add(_undoStack.removeLast()); // Save current state to redo
      _textController.text = _undoStack.last; // Restore last saved state
      _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      _undoStack.add(_redoStack.last); // Move last redo state to undo stack
      _textController.text = _redoStack.removeLast(); // Restore redo state
      _textController.selection = TextSelection.collapsed(offset: _textController.text.length);
    }
  }



  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(source: source);
      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // Show full-screen preview for confirmation
        final bool? confirm = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ImagePreviewScreen(
              imageFile: imageFile,
              onConfirm: () {
                Navigator.pop(context, true); // Return true when confirmed
              },
            ),
          ),
        );


        if (confirm == true) {
          setState(() {
            _selectedImage = imageFile;
          });

          final inputImage = InputImage.fromFile(_selectedImage!);
          final recognizedText = await _textRecognizer.processImage(inputImage);

          setState(() {
            _saveToUndoStack();
            _displayedText += '\n\n' + recognizedText.text;
            _textController.text = _displayedText;
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing image')),
      );
    }
  }

  void _navigateToImageSelectionScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImageSelectionScreen(
          onImageSelected: (File selectedImage) async {
            setState(() {
              _selectedImage = selectedImage;
            });

            final inputImage = InputImage.fromFile(_selectedImage!);
            final recognizedText = await _textRecognizer.processImage(inputImage);

            setState(() {
              _saveToUndoStack();
              _displayedText += '\n\n' + recognizedText.text;
              _textController.text = _displayedText;
            });
          },
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR Result'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'OCR Result',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.undo),
                      tooltip: 'Undo',
                      onPressed: _undoStack.isNotEmpty ? _undo : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.redo),
                      tooltip: 'Redo',
                      onPressed: _redoStack.isNotEmpty ? _redo : null,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Extracted text will appear here',
                ),
                onChanged: (value) {
                  if (_textController.text != (_undoStack.isEmpty ? '' : _undoStack.last)) {
                    _saveToUndoStack();
                  }
                  setState(() {
                    _displayedText = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _navigateToImageSelectionScreen,
              child: const Text('Add More'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => GenSumAndRevScreen()),
                );
              },
              child: const Text('Generate Summary and Reviewer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}


class ImageSelectionScreen extends StatefulWidget {
  final Function(File) onImageSelected;

  const ImageSelectionScreen({Key? key, required this.onImageSelected}) : super(key: key);

  @override
  _ImageSelectionScreenState createState() => _ImageSelectionScreenState();
}

class _ImageSelectionScreenState extends State<ImageSelectionScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(cameras[0], ResolutionPreset.medium);
        await _cameraController!.initialize();
        setState(() {
          _isCameraInitialized = true;
          _isPermissionGranted = true;
        });
      }
    } catch (e) {
      setState(() {
        _isPermissionGranted = false;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      final XFile file = await _cameraController!.takePicture();
      _showPreviewScreen(File(file.path));
    }
  }

  Future<void> _pickImageFromGallery() async {
    final XFile? pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _showPreviewScreen(File(pickedFile.path));
    }
  }

  void _showPreviewScreen(File imageFile) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ImagePreviewScreen(
          imageFile: imageFile,
          onConfirm: () {
            widget.onImageSelected(imageFile);
            Navigator.pop(context); // Go back to OCR screen
            Navigator.pop(context); // Close selection screen
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          if (_isCameraInitialized)
            Positioned.fill(
              child: CameraPreview(_cameraController!),
            ),
          if (!_isCameraInitialized)
            const Center(child: CircularProgressIndicator()),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _takePhoto,
                  child: const Text('Take a Picture'),
                ),
                ElevatedButton(
                  onPressed: _pickImageFromGallery,
                  child: const Text('Pick Image from Gallery'),
                ),
              ],
            ),
          ),
        ],
      ),
    );

  }
}



class ImagePreviewScreen extends StatelessWidget {
  final File imageFile;
  final VoidCallback onConfirm;

  const ImagePreviewScreen({Key? key, required this.imageFile, required this.onConfirm}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Image'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: onConfirm,
          ),
        ],
      ),
      body: Center(
        child: Image.file(imageFile),
      ),
    );
  }
}

