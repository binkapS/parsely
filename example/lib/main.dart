import 'package:binkap_parsely/binkap_parsely.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.deepPurple,
          title: const Text(
            'Parsely Example',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ),
        body: Center(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple,
                  Colors.purpleAccent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(5, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.all(30),
            child: Parsely(
              text:
                  'Visit me https://binkap.com, or you could send me an email at rea.desert.tiger@gmail.com, Supposedly you prefer calls reach me at +2348068989116 or simply use #binkap on twitter',
              textAlign: TextAlign.center,
              options: ParselyOptions(
                parseMentionTag: false,
                humanize: true,
                parsePhone: true,
                parseHashTag: true,
                parseEmail: true,
                parseLink: true,
              ),
              mask: ParselyMask(
                matches: [
                  '+2348068989116',
                ],
                masks: [
                  'My Contact',
                ],
              ),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'DancingScript', // Feel free to change the font
              ),
              parsedStyle: const TextStyle(
                color: Color.fromARGB(255, 33, 243, 86),
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: 'DancingScript', // Feel free to change the font
              ),
              onTap: (element) {
                switch (element.type) {
                  case ParselyType.link:
                    print('Do something with the link: ${element.parsed}');
                    break;
                  case ParselyType.email:
                    print('Do Something with the email: ${element.parsed}');
                    break;
                  case ParselyType.phone:
                    print(
                        'Do Something with the phone number: ${element.parsed}');
                    break;
                  case ParselyType.hashTag:
                    print('Do Something with the hashTag: ${element.parsed}');
                    break;
                  case ParselyType.mentionTag:
                    print('Do Something with the @mention: ${element.parsed}');
                    break;
                  default:
                    print('Something');
                }
              },
            ),
          ),
        ),
      ),
    );
  }
}
