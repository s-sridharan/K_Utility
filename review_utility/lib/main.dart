import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static const Color navyBlue = Color(0xFF000080);
  static const Color lightGrey = Color(0xFFD3D3D3);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sentiment Analysis',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: navyBlue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: lightGrey,
        ),
        textTheme: TextTheme(
          bodyMedium: TextStyle(color: Colors.black),
        ),
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(color: navyBlue),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: navyBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: navyBlue),
          ),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Colors.white,
          primary: navyBlue,
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _googleController = TextEditingController();
  final TextEditingController _appleController = TextEditingController();
  final TextEditingController _twitterController = TextEditingController();

  int _googleTotalReviews = 0;
  Map<String, int> _googleSentimentBuckets = {};
  String _googleMessage = '';

  int _appleTotalReviews = 0;
  Map<String, int> _appleSentimentBuckets = {};
  String _appleMessage = '';

  int _twitterTotalReviews = 0;
  Map<String, int> _twitterSentimentBuckets = {};
  String _twitterMessage = '';

  bool _isLoading = false;
  String _progressLog = '';

  @override
  void dispose() {
    super.dispose();
    _shutdownServer();
  }

  Future<void> _shutdownServer() async {
    final response = await http.post(
      Uri.parse('http://127.0.0.1:5000/shutdown'),
    );

    if (response.statusCode == 200) {
      print('Server shut down successfully');
    } else {
      print('Failed to shut down server');
    }
  }

  Future<void> _analyzeSentiment(String type, String text) async {
    setState(() {
      _isLoading = true;
      _progressLog = 'Processing $type reviews...';
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:5000/sentimentAnalysis'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{'type': type, 'text': text}),
      );

      setState(() {
        _isLoading = false;
      });

      if (response.statusCode == 200) {
        String responseBody = response.body;

        // Sanitize JSON by replacing NaN values with null
        responseBody = responseBody.replaceAll('NaN', 'null');
        print('Sanitized Response body: $responseBody');

        try {
          final data = jsonDecode(responseBody);
          setState(() {
            if (type == 'google') {
              _googleTotalReviews = data['totalReviews'] ?? 0;
              _googleSentimentBuckets = Map<String, int>.from(data['sentimentBuckets'] ?? {});
              _googleMessage = 'Analysis complete';
            } else if (type == 'apple') {
              _appleTotalReviews = data['totalReviews'] ?? 0;
              _appleSentimentBuckets = Map<String, int>.from(data['sentimentBuckets'] ?? {});
              _appleMessage = 'Analysis complete';
            } else if (type == 'twitter') {
              _twitterTotalReviews = data['totalReviews'] ?? 0;
              _twitterSentimentBuckets = Map<String, int>.from(data['sentimentBuckets'] ?? {});
              _twitterMessage = 'Analysis complete';
            }
          });
        } catch (e) {
          setState(() {
            if (type == 'google') {
              _googleTotalReviews = 0;
              _googleSentimentBuckets = {};
              _googleMessage = 'Failed to parse response';
            } else if (type == 'apple') {
              _appleTotalReviews = 0;
              _appleSentimentBuckets = {};
              _appleMessage = 'Failed to parse response';
            } else if (type == 'twitter') {
              _twitterTotalReviews = 0;
              _twitterSentimentBuckets = {};
              _twitterMessage = 'Failed to parse response';
            }
          });
        }
      } else {
        setState(() {
          if (type == 'google') {
            _googleTotalReviews = 0;
            _googleSentimentBuckets = {};
            _googleMessage = 'Analysis failed';
          } else if (type == 'apple') {
            _appleTotalReviews = 0;
            _appleSentimentBuckets = {};
            _appleMessage = 'Analysis failed';
          } else if (type == 'twitter') {
            _twitterTotalReviews = 0;
            _twitterSentimentBuckets = {};
            _twitterMessage = 'Analysis failed';
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        if (type == 'google') {
          _googleTotalReviews = 0;
          _googleSentimentBuckets = {};
          _googleMessage = 'Error occurred: $e';
        } else if (type == 'apple') {
          _appleTotalReviews = 0;
          _appleSentimentBuckets = {};
          _appleMessage = 'Error occurred: $e';
        } else if (type == 'twitter') {
          _twitterTotalReviews = 0;
          _twitterSentimentBuckets = {};
          _twitterMessage = 'Error occurred: $e';
        }
      });
    }
  }

  Widget _buildInstructionText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: MyApp.navyBlue),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(color: MyApp.navyBlue, fontSize: 12),
          isDense: true,
          contentPadding: EdgeInsets.all(8),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyApp.navyBlue),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyApp.navyBlue),
          ),
        ),
        style: TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildAnalyzeButton(VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text('Analyze'),
        style: ElevatedButton.styleFrom(
          backgroundColor: MyApp.navyBlue,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          textStyle: TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

  Widget _buildResultSection(int totalReviews, Map<String, int> sentimentBuckets, String message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Total Reviews Processed: $totalReviews',
          style: TextStyle(fontSize: 14, color: MyApp.navyBlue),
        ),
        SizedBox(height: 10),
        _buildSentimentDistributionChart(sentimentBuckets),
        SizedBox(height: 10),
        Text(
          message,
          style: TextStyle(fontSize: 12, color: Colors.red),
        ),
      ],
    );
  }

  Widget _buildSentimentDistributionChart(Map<String, int> sentimentBuckets) {
    final sentimentOrder = [
      'Strongly Negative',
      'Somewhat Negative',
      'Neutral',
      'Somewhat Positive',
      'Strongly Positive'
    ];

    final emoticons = {
      'Strongly Negative': '😡',
      'Somewhat Negative': '😟',
      'Neutral': '😐',
      'Somewhat Positive': '🙂',
      'Strongly Positive': '😁',
    };

    final data = sentimentOrder.map((sentiment) {
      int count = sentimentBuckets[sentiment] ?? 0;
      Color color;
      switch (sentiment) {
        case 'Strongly Positive':
          color = Color(0xFF66BB6A); // Light Green
          break;
        case 'Somewhat Positive':
          color = Color(0xFF9CCC65); // Light Lime
          break;
        case 'Neutral':
          color = Color(0xFFBDBDBD); // Light Grey
          break;
        case 'Somewhat Negative':
          color = Color(0xFFFFB74D); // Dull Orange
          break;
        case 'Strongly Negative':
          color = Color(0xFFEF5350); // Light Red
          break;
        default:
          color = Colors.grey;
          break;
      }
      return SentimentBucket(emoticons[sentiment] ?? '', count, color);
    }).toList();

    return SizedBox(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: CategoryAxis(),
        series: <ChartSeries>[
          ColumnSeries<SentimentBucket, String>(
            dataSource: data,
            xValueMapper: (SentimentBucket bucket, _) => bucket.label,
            yValueMapper: (SentimentBucket bucket, _) => bucket.count,
            pointColorMapper: (SentimentBucket bucket, _) => bucket.color,
            dataLabelSettings: DataLabelSettings(isVisible: true),
          )
        ],
      ),
    );
  }
}

class SentimentBucket {
  final String label;
  final int count;
  final Color color;

  SentimentBucket(this.label, this.count, this.color);
}




// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'dart:io'; // Import the dart:io library
//
// void main() {
//   runApp(MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   static const Color navyBlue = Color(0xFF000080);
//   static const Color lightGrey = Color(0xFFD3D3D3);
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Sentiment Analysis',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         primaryColor: navyBlue,
//         scaffoldBackgroundColor: Colors.white,
//         appBarTheme: AppBarTheme(
//           backgroundColor: lightGrey,
//         ),
//         textTheme: TextTheme(
//           bodyMedium: TextStyle(color: Colors.black),
//         ),
//         inputDecorationTheme: InputDecorationTheme(
//           labelStyle: TextStyle(color: navyBlue),
//           enabledBorder: OutlineInputBorder(
//             borderSide: BorderSide(color: navyBlue),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderSide: BorderSide(color: navyBlue),
//           ),
//         ),
//         colorScheme: ColorScheme.fromSwatch().copyWith(
//           secondary: Colors.white,
//           primary: navyBlue,
//         ),
//       ),
//       home: HomePage(),
//     );
//   }
// }
//
// class HomePage extends StatefulWidget {
//   @override
//   _HomePageState createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   final TextEditingController _googleController = TextEditingController();
//   final TextEditingController _appleController = TextEditingController();
//   final TextEditingController _twitterController = TextEditingController();
//
//   int _googleTotalReviews = 0;
//   Map<String, int> _googleSentimentBuckets = {};
//
//   int _appleTotalReviews = 0;
//   Map<String, int> _appleSentimentBuckets = {};
//
//   int _twitterTotalReviews = 0;
//   Map<String, int> _twitterSentimentBuckets = {};
//
//   @override
//   void dispose() {
//     super.dispose();
//     _shutdownServer();
//   }
//
//   Future<void> _shutdownServer() async {
//     final response = await http.post(
//       Uri.parse('http://127.0.0.1:5000/shutdown'),
//     );
//
//     if (response.statusCode == 200) {
//       print('Server shut down successfully');
//     } else {
//       print('Failed to shut down server');
//     }
//   }
//
//   Future<void> _analyzeSentiment(String type, String text) async {
//     try {
//       final response = await http.post(
//         Uri.parse('http://127.0.0.1:5000/sentimentAnalysis'),
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//         },
//         body: jsonEncode(<String, String>{'type': type, 'text': text}),
//       );
//
//       if (response.statusCode == 200) {
//         String responseBody = response.body;
//
//         // Sanitize JSON by replacing NaN values with null
//         responseBody = responseBody.replaceAll('NaN', 'null');
//         print('Sanitized Response body: $responseBody'); // Log the sanitized response body
//
//         try {
//           final data = jsonDecode(responseBody);
//           setState(() {
//             if (type == 'google') {
//               _googleTotalReviews = data['totalReviews'] ?? 0;
//               _googleSentimentBuckets = Map<String, int>.from(data['sentimentBuckets'] ?? {});
//             } else if (type == 'apple') {
//               _appleTotalReviews = data['totalReviews'] ?? 0;
//               _appleSentimentBuckets = Map<String, int>.from(data['sentimentBuckets'] ?? {});
//             } else if (type == 'twitter') {
//               _twitterTotalReviews = data['totalReviews'] ?? 0;
//               _twitterSentimentBuckets = Map<String, int>.from(data['sentimentBuckets'] ?? {});
//             }
//           });
//         } catch (e) {
//           setState(() {
//             if (type == 'google') {
//               _googleTotalReviews = 0;
//               _googleSentimentBuckets = {};
//             } else if (type == 'apple') {
//               _appleTotalReviews = 0;
//               _appleSentimentBuckets = {};
//             } else if (type == 'twitter') {
//               _twitterTotalReviews = 0;
//               _twitterSentimentBuckets = {};
//             }
//           });
//         }
//       } else {
//         setState(() {
//           if (type == 'google') {
//             _googleTotalReviews = 0;
//             _googleSentimentBuckets = {};
//           } else if (type == 'apple') {
//             _appleTotalReviews = 0;
//             _appleSentimentBuckets = {};
//           } else if (type == 'twitter') {
//             _twitterTotalReviews = 0;
//             _twitterSentimentBuckets = {};
//           }
//         });
//       }
//     } catch (e) {
//       setState(() {
//         if (type == 'google') {
//           _googleTotalReviews = 0;
//           _googleSentimentBuckets = {};
//         } else if (type == 'apple') {
//           _appleTotalReviews = 0;
//           _appleSentimentBuckets = {};
//         } else if (type == 'twitter') {
//           _twitterTotalReviews = 0;
//           _twitterSentimentBuckets = {};
//         }
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Sentiment Analysis'),
//       ),
//       body: Container(
//         color: Color(0xFFB0B0B0), // Darker grey outer background color
//         child: Center(
//           child: SingleChildScrollView(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0), // Increased padding
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(maxWidth: 500),
//                 child: Container(
//                   color: Colors.blue[50], // Lighter blue for the inner scrollable container
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildInstructionText(
//                           'Google Play Store: Enter the URL of the app page from the Google Play Store to analyze the reviews.'),
//                       _buildTextField(_googleController, 'Enter Google Play Store link'),
//                       _buildAnalyzeButton(() => _analyzeSentiment('google', _googleController.text)),
//                       _buildResultSection(_googleTotalReviews, _googleSentimentBuckets),
//
//                       SizedBox(height: 20), // Spacing
//
//                       _buildInstructionText(
//                           'Apple App Store: Enter the URL of the app page from the Apple App Store to analyze the reviews.'),
//                       _buildTextField(_appleController, 'Enter Apple App Store link'),
//                       _buildAnalyzeButton(() => _analyzeSentiment('apple', _appleController.text)),
//                       _buildResultSection(_appleTotalReviews, _appleSentimentBuckets),
//
//                       SizedBox(height: 20), // Spacing
//
//                       _buildInstructionText(
//                           'Twitter: Enter a hashtag to analyze the tweets associated with it.'),
//                       _buildTextField(_twitterController, 'Enter Twitter hashtag'),
//                       _buildAnalyzeButton(() => _analyzeSentiment('twitter', _twitterController.text)),
//                       _buildResultSection(_twitterTotalReviews, _twitterSentimentBuckets),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInstructionText(String text) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5.0),
//       child: Text(
//         text,
//         style: TextStyle(fontSize: 14, color: MyApp.navyBlue),
//       ),
//     );
//   }
//
//   Widget _buildTextField(TextEditingController controller, String labelText) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5.0),
//       child: TextField(
//         controller: controller,
//         decoration: InputDecoration(
//           labelText: labelText,
//           labelStyle: TextStyle(color: MyApp.navyBlue, fontSize: 12),
//           isDense: true,
//           contentPadding: EdgeInsets.all(8),
//           enabledBorder: OutlineInputBorder(
//             borderSide: BorderSide(color: MyApp.navyBlue),
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderSide: BorderSide(color: MyApp.navyBlue),
//           ),
//         ),
//         style: TextStyle(fontSize: 12),
//       ),
//     );
//   }
//
//   Widget _buildAnalyzeButton(VoidCallback onPressed) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 5.0),
//       child: ElevatedButton(
//         onPressed: onPressed,
//         child: Text('Analyze'),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: MyApp.navyBlue,
//           foregroundColor: Colors.white,
//           padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
//           textStyle: TextStyle(fontSize: 12),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildResultSection(int totalReviews, Map<String, int> sentimentBuckets) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           'Total Reviews Processed: $totalReviews',
//           style: TextStyle(fontSize: 14, color: MyApp.navyBlue),
//         ),
//         _buildSentimentDistributionChart(sentimentBuckets),
//       ],
//     );
//   }
//
//   Widget _buildSentimentDistributionChart(Map<String, int> sentimentBuckets) {
//     final sentimentOrder = [
//       'Strongly Negative',
//       'Somewhat Negative',
//       'Neutral',
//       'Somewhat Positive',
//       'Strongly Positive'
//     ];
//
//     final emoticons = {
//       'Strongly Negative': '😡',
//       'Somewhat Negative': '😟',
//       'Neutral': '😐',
//       'Somewhat Positive': '🙂',
//       'Strongly Positive': '😁',
//     };
//
//     final data = sentimentOrder.map((sentiment) {
//       int count = sentimentBuckets[sentiment] ?? 0;
//       Color color;
//       switch (sentiment) {
//         case 'Strongly Positive':
//           color = Color(0xFF66BB6A); // Light Green
//           break;
//         case 'Somewhat Positive':
//           color = Color(0xFF9CCC65); // Light Lime
//           break;
//         case 'Neutral':
//           color = Color(0xFFBDBDBD); // Light Grey
//           break;
//         case 'Somewhat Negative':
//           color = Color(0xFFFFB74D); // Dull Orange
//           break;
//         case 'Strongly Negative':
//           color = Color(0xFFEF5350); // Light Red
//           break;
//         default:
//           color = Colors.grey;
//           break;
//       }
//       return SentimentBucket(emoticons[sentiment] ?? '', count, color);
//     }).toList();
//
//     return SizedBox(
//       height: 300,
//       child: SfCartesianChart(
//         primaryXAxis: CategoryAxis(),
//         series: <ChartSeries>[
//           ColumnSeries<SentimentBucket, String>(
//             dataSource: data,
//             xValueMapper: (SentimentBucket bucket, _) => bucket.label,
//             yValueMapper: (SentimentBucket bucket, _) => bucket.count,
//             pointColorMapper: (SentimentBucket bucket, _) => bucket.color,
//             dataLabelSettings: DataLabelSettings(isVisible: true),
//           )
//         ],
//       ),
//     );
//   }
// }
//
// class SentimentBucket {
//   final String label;
//   final int count;
//   final Color color;
//
//   SentimentBucket(this.label, this.count, this.color);
// }
//
