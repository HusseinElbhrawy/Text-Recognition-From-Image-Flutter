import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:text_recognition_flutter/components/image_widget.dart';
import 'package:text_recognition_flutter/models/recognition_response.dart';
import 'package:text_recognition_flutter/recognizer/interface/text_recognizer.dart';
import 'package:text_recognition_flutter/recognizer/mlkit_text_recognizer.dart';
import 'package:text_recognition_flutter/recognizer/tesseract_text_recognizer.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late ImagePicker _picker;
  late ITextRecognizer _recognizer;

  RecognitionResponse? _response;
  bool isLoading = false;
  @override
  void initState() {
    super.initState();
    _picker = ImagePicker();

    ///! Can be [MLKitTextRecognizer] or [TesseractTextRecognizer]
    // _recognizer = MLKitTextRecognizer();
    _recognizer = TesseractTextRecognizer();
  }

  @override
  void dispose() {
    super.dispose();
    if (_recognizer is MLKitTextRecognizer) {
      (_recognizer as MLKitTextRecognizer).dispose();
    }
  }

  void processImage(String imgPath) async {
    isLoading = true;
    setState(() {});
    final recognizedText = await _recognizer.processImage(imgPath);

    setState(() {
      _response = RecognitionResponse(
        imgPath: imgPath,
        recognizedText: recognizedText,
      );
      isLoading = false;
    });
  }

  Future<String?> obtainImage(ImageSource source) async {
    final file = await _picker.pickImage(source: source);
    return file?.path;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Text Recognition'),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => imagePickAlert(
                  onCameraPressed: () async {
                    obtainImage(ImageSource.camera).then(
                      (value) {
                        if (value == null) return;
                        Navigator.of(context).pop();
                        processImage(value);
                      },
                    );
                  },
                  onGalleryPressed: () async {
                    obtainImage(ImageSource.gallery).then(
                      (value) {
                        if (value == null) return;
                        Navigator.of(context).pop();
                        processImage(value);
                      },
                    );
                  },
                ),
              );
            },
            child: const Icon(Icons.add),
          ),
          body: _response == null
              ? const Center(
                  child: Text(
                    'Pick image to continue',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                )
              : ListView(
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.width,
                      width: MediaQuery.of(context).size.width,
                      child: Image.file(File(_response!.imgPath)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Recognized Text",
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(
                                        text: _response!.recognizedText),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Copied to Clipboard'),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.copy),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(_response!.recognizedText),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
        Visibility(
          visible: isLoading,
          child: Container(
            color: Colors.grey.withOpacity(.25),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      ],
    );
  }
}
