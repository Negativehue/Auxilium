import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final String extractedText;

  const ResultScreen({Key? key, required this.extractedText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generated Summary and Reviewer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Text(
            extractedText,
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
