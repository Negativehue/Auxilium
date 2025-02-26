import 'package:flutter/material.dart';

class SumAndRevResultScreen extends StatelessWidget {
  final String resultText;

  // Constructor to receive the generated text
  const SumAndRevResultScreen({Key? key, required this.resultText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Generated Result")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Generated Summary and Reviewer:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(resultText, style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
