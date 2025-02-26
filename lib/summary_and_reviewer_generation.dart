import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'sum_and_rev_result.dart'; // Make sure this file exists

class GenSumAndRevScreen extends StatefulWidget {
  @override
  _GenSumAndRevScreenState createState() => _GenSumAndRevScreenState();
}

class _GenSumAndRevScreenState extends State<GenSumAndRevScreen> {
  String? _selectedSummary;
  String? _selectedReviewer;
  bool _isLoading = false;

  Future<void> _generateContent() async {
    if (_selectedSummary == null || _selectedReviewer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select both options.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/generate'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "summary_type": _selectedSummary,
          "reviewer_type": _selectedReviewer,
          "extracted_text": "Your OCR extracted text here"
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        if (result.containsKey("response")) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SumAndRevResultScreen(resultText: result["response"]),
            ),
          );
        } else {
          throw Exception("Invalid response format");
        }
      } else {
        final errorResult = jsonDecode(response.body);
        throw Exception("Failed: ${errorResult['error']}");
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generate Summary and Reviewer")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSelectionSection(
              title: "Select the type of summarization:",
              options: ["Paragraph", "Bulletpoints"],
              groupValue: _selectedSummary,
              onChanged: (value) => setState(() => _selectedSummary = value),
            ),
            _buildSelectionSection(
              title: "Select the type of reviewer:",
              options: ["Multiple Choice", "True or False", "Fill in the Blank", "Identification"],
              groupValue: _selectedReviewer,
              onChanged: (value) => setState(() => _selectedReviewer = value),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: (_selectedSummary != null && _selectedReviewer != null) ? _generateContent : null,
                  child: const Text("Generate"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionSection({
    required String title,
    required List<String> options,
    required String? groupValue,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ...options.map((option) => RadioListTile<String>(
          title: Text(option),
          value: option,
          groupValue: groupValue,
          onChanged: onChanged,
        )),
      ],
    );
  }
}
