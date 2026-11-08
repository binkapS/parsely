// ignore_for_file: avoid_print
//
// Screenshot app — not the kitchen-sink demo in main.dart.
// Renders three showcase cards for README / pub.dev screenshots.
// Build & capture:
//   cd example && flutter build web -t lib/screenshot_main.dart
//   <serve build/web>, then headless-Chrome --screenshot
import 'package:binkap_parsely/binkap_parsely.dart';
import 'package:flutter/material.dart';

const _sample = 'Visit https://binkap.com, email rea.desert.tiger@gmail.com, '
    'call +2348068989116, use #binkap and @dartlang.';

void main() {
  runApp(const ScreenshotApp());
}

class ScreenshotApp extends StatelessWidget {
  const ScreenshotApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.deepPurple);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F6F6),
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Parsely'),
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _card(
                  scheme,
                  title: 'All entity types',
                  child: Parsely(
                    text: _sample,
                    style: TextStyle(color: scheme.onSurface, fontSize: 18),
                    onTap: (e) => print('${e.type.name}: ${e.parsed}'),
                  ),
                ),
                const SizedBox(height: 24),
                _card(
                  scheme,
                  title: 'Per-type styles',
                  child: Parsely(
                    text: _sample,
                    style: TextStyle(color: scheme.onSurface, fontSize: 18),
                    parsedStyles: const {
                      ParselyType.link: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      ParselyType.email: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                      ParselyType.phone: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                      ParselyType.hashTag: TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                      ParselyType.mentionTag: TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                      ),
                    },
                    onTap: (e) => print('${e.type.name}: ${e.parsed}'),
                  ),
                ),
                const SizedBox(height: 24),
                _card(
                  scheme,
                  title: 'Masking (display-only)',
                  child: Parsely(
                    text: _sample,
                    style: TextStyle(color: scheme.onSurface, fontSize: 18),
                    masks: const ParselyMasks(exact: {
                      '+2348068989116': 'My Contact',
                      'rea.desert.tiger@gmail.com': 'hidden@example.com',
                    }),
                    options: const ParselyOptions(stripLinkScheme: true),
                    onTap: (e) => print('${e.type.name}: ${e.parsed}'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(ColorScheme scheme,
      {required String title, required Widget child}) {
    return Container(
      width: 720,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
