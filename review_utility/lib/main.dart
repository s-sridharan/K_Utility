import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentiment Analysis',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: MyHomePage(title: 'Sentiment Analysis'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _controller = TextEditingController();
  String _polarity = '';
  String _subjectivity = '';
  String _imageUrl = '';

  Future<void> _analyzeSentiment(String url) async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/analyze'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{'url': url}),
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _polarity = data['polarity'].toString();
        _subjectivity = data['subjectivity'].toString();
        _imageUrl = data['imageUrl'];
      });
    } else {
      setState(() {
        _polarity = 'Error';
        _subjectivity = 'Error';
        _imageUrl = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Enter a sentence',
                labelStyle: TextStyle(color: Colors.blue),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blueAccent),
                ),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _analyzeSentiment(_controller.text);
              },
              child: Text('Analyze Sentiment'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Button background color
                foregroundColor: Colors.white, // Text color
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Polarity: $_polarity',
              style: TextStyle(fontSize: 18, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            Text(
              'Subjectivity: $_subjectivity',
              style: TextStyle(fontSize: 18, color: Colors.blue),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            _imageUrl.isNotEmpty
                ? Image.network(_imageUrl)
                : Container(),
          ],
        ),
      ),
    );
  }
}
