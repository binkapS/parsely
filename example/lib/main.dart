import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:binkap_parsely/binkap_parsely.dart';

const _sampleText = 'Visit https://binkap.com or www.example.com, email '
    'rea.desert.tiger@gmail.com, call +2348068989116, '
    'follow #binkap and talk to @dartlang about #flutter.';

const _rtlSample = 'مرحبا @dartlang، زر https://binkap.com وراسلني '
    'rea.desert.tiger@gmail.com #مرحبا';

const _unicodeSample = '#café ☕ #100DaysOfCode #日本語 #🎨 #emoji_الحب @café?';

enum _MaskMode { none, exact, partialLast, legacy }

void main() {
  runApp(const ParselyExampleApp());
}

class ParselyExampleApp extends StatefulWidget {
  const ParselyExampleApp({super.key});

  @override
  State<ParselyExampleApp> createState() => _ParselyExampleAppState();
}

class _ParselyExampleAppState extends State<ParselyExampleApp> {
  bool _dark = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parsely Kitchen Sink',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _dark ? ThemeMode.dark : ThemeMode.light,
      home: DemoPage(
        dark: _dark,
        onToggleDark: () => setState(() => _dark = !_dark),
      ),
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key, required this.dark, required this.onToggleDark});

  final bool dark;
  final VoidCallback onToggleDark;

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  bool _parseEmail = true;
  bool _parseLink = true;
  bool _parsePhone = true;
  bool _parseHashtag = true;
  bool _parseMention = true;
  bool _stripLinkScheme = true;
  bool _stripMentionPrefix = true;
  bool _humanize = true;

  bool _showPlain = true;
  bool _showLive = true;
  bool _showOptions = true;
  bool _showMasking = true;
  bool _showHeadless = true;
  bool _showSelectable = true;
  bool _showStyles = true;
  bool _showSamples = true;

  _MaskMode _maskMode = _MaskMode.exact;

  final Map<ParselyType, Color> _typeColors = {
    ParselyType.link: Colors.blue,
    ParselyType.email: Colors.green.shade700,
    ParselyType.phone: Colors.orange.shade800,
    ParselyType.hashTag: Colors.purple,
    ParselyType.mentionTag: Colors.pink,
  };

  ParselyOptions get _options => ParselyOptions(
        parseEmail: _parseEmail,
        parseLink: _parseLink,
        parsePhone: _parsePhone,
        parseHashtag: _parseHashtag,
        parseMention: _parseMention,
        stripLinkScheme: _stripLinkScheme,
        stripMentionPrefix: _stripMentionPrefix,
        humanize: _humanize,
      );

  ParselyMasks? get _masks {
    return switch (_maskMode) {
      _MaskMode.exact => const ParselyMasks(
          exact: {
            '+2348068989116': 'My Contact',
            'rea.desert.tiger@gmail.com': '•••@example.com',
          },
        ),
      _MaskMode.none => null,
      // maskBuilder modes are wired via _maskBuilder; masks stay null.
      _MaskMode.partialLast => null,
      _MaskMode.legacy => null,
    };
  }

  ParselyMaskBuilder? get _maskBuilder {
    if (_maskMode != _MaskMode.partialLast) return null;
    return ParselyMaskBuilders.partialLast(
      type: ParselyType.phone,
      keepLast: 4,
    );
  }

  // ignore: deprecated_member_use
  ParselyMask? get _legacyMask {
    if (_maskMode != _MaskMode.legacy) return null;
    // ignore: deprecated_member_use
    return ParselyMask(
      matches: const ['+2348068989116'],
      masks: const ['My Contact'],
    );
  }

  Map<ParselyType, TextStyle> get _parsedStyles => {
        for (final entry in _typeColors.entries)
          entry.key: TextStyle(
            color: entry.value,
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
      };

  void _handleTap(ParselyElement e) {
    debugPrint('Tapped ${e.type.name}: ${e.parsed} '
        'display=${e.displayText} offsets=${e.start}-${e.end} '
        'uri=${e.uri}');
    if (!mounted) return;
    final uri = e.uri;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(uri == null
            ? 'Tapped ${e.type.name}: ${e.parsed}'
            : 'Tapped ${e.type.name}: ${e.parsed} → $uri'),
        action: SnackBarAction(
          label: 'Copy',
          onPressed: () => _copy(e.parsed),
        ),
      ),
    );
  }

  void _copy(String text) {
    Clipboard.setData(ClipboardData(text: text));
    debugPrint('Copied $text');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied: $text')),
    );
  }

  void _launchPreview(ParselyElement e) {
    final uri = e.uri;
    debugPrint('Launch preview for ${e.type.name} ${e.parsed}: $uri');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(uri == null
            ? 'No launch URL for ${e.type.name} (${e.parsed}). '
                'Wire url_launcher if you need a real launch.'
            : 'Would launch → $uri. '
                'No url_launcher dep in this demo.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parsely Kitchen Sink'),
        actions: [
          IconButton(
            tooltip: widget.dark ? 'Switch to light' : 'Switch to dark',
            icon: Icon(widget.dark ? Icons.light_mode : Icons.dark_mode),
            onPressed: widget.onToggleDark,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _themeNote(context),
          _liveSectionsCard(),
          if (_showPlain) _plainSection(scheme),
          if (_showLive) _liveSection(scheme),
          if (_showOptions) _optionsSection(),
          if (_showMasking) _maskingSection(scheme),
          if (_showHeadless) _headlessSection(scheme),
          if (_showSelectable) _selectableSection(scheme),
          if (_showStyles) _stylesSection(scheme),
          if (_showSamples) _samplesSection(scheme),
        ],
      ),
    );
  }

  Widget _themeNote(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.primaryContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.dark
            ? 'Dark theme ON (MaterialApp darkTheme). '
                'This demo uses withValues() for alpha.'
            : 'Light theme ON. Tap the moon icon for dark mode. '
                'This demo uses withValues() for alpha.',
      ),
    );
  }

  Widget _liveSectionsCard() {
    Widget tile(String label, bool value, ValueChanged<bool> onChanged) {
      return SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sections (toggled live)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            tile('Plain / default', _showPlain,
                (v) => setState(() => _showPlain = v)),
            tile('Live Parsely', _showLive,
                (v) => setState(() => _showLive = v)),
            tile('Options switches', _showOptions,
                (v) => setState(() => _showOptions = v)),
            tile('Masking demo', _showMasking,
                (v) => setState(() => _showMasking = v)),
            tile('Headless extract()', _showHeadless,
                (v) => setState(() => _showHeadless = v)),
            tile('SelectableParsely', _showSelectable,
                (v) => setState(() => _showSelectable = v)),
            tile('Per-type styles', _showStyles,
                (v) => setState(() => _showStyles = v)),
            tile('RTL + unicode samples', _showSamples,
                (v) => setState(() => _showSamples = v)),
          ],
        ),
      ),
    );
  }

  Widget _plainSection(ColorScheme scheme) {
    return Card(
      color: scheme.primaryContainer.withValues(alpha: 0.9),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '1 · Plain / default (no options, no mask)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Parsely(
              text: _sampleText,
              style: TextStyle(color: scheme.onPrimaryContainer, fontSize: 16),
              onTap: _handleTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _liveSection(ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '2 · Live Parsely (options + styles + mask wired)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Parsely(
              text: _sampleText,
              style: TextStyle(color: scheme.onSurface, fontSize: 16),
              parsedStyles: _parsedStyles,
              options: _options,
              masks: _masks,
              maskBuilder: _maskBuilder,
              // ignore: deprecated_member_use
              mask: _legacyMask,
              onTap: _handleTap,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap any entity → SnackBar shows element.uri (or “no URL”). '
              'Copy button copies the original value (display-only masking).',
              style: TextStyle(fontSize: 12),
            ),
            Wrap(
              spacing: 8,
              children: [
                FilledButton.tonal(
                  onPressed: () => _copy(_sampleText),
                  child: const Text('Copy sample text'),
                ),
                FilledButton.tonal(
                  onPressed: () => _launchPreview(
                    const ParselyElement(
                      type: ParselyType.link,
                      parsed: 'https://binkap.com',
                    ),
                  ),
                  child: const Text('Launch preview (link)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionsSection() {
    Widget tile(String label, bool value, ValueChanged<bool> onChanged) {
      return SwitchListTile(
        title: Text(label),
        value: value,
        onChanged: onChanged,
      );
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '3 · ParselyOptions toggles',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            tile('parseEmail', _parseEmail,
                (v) => setState(() => _parseEmail = v)),
            tile(
                'parseLink', _parseLink, (v) => setState(() => _parseLink = v)),
            tile('parsePhone', _parsePhone,
                (v) => setState(() => _parsePhone = v)),
            tile('parseHashtag (#…)', _parseHashtag,
                (v) => setState(() => _parseHashtag = v)),
            tile('parseMention (@…)', _parseMention,
                (v) => setState(() => _parseMention = v)),
            const Divider(),
            tile('stripLinkScheme (strip https://www.)', _stripLinkScheme,
                (v) => setState(() => _stripLinkScheme = v)),
            tile('stripMentionPrefix (strip @)', _stripMentionPrefix,
                (v) => setState(() => _stripMentionPrefix = v)),
            tile('humanize (legacy master flag)', _humanize,
                (v) => setState(() => _humanize = v)),
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(
                'Note: humanize is the legacy master switch. '
                'When stripLinkScheme/stripMentionPrefix are set, they win; '
                'otherwise they fall back to humanize. '
                'Effective behavior: effectiveStripLinkScheme = '
                'stripLinkScheme ?? humanize (same for mentions).',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _maskingSection(ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '4 · Masking demo (display-only; parsed is unchanged)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            RadioGroup<_MaskMode>(
              groupValue: _maskMode,
              onChanged: (v) => setState(() => _maskMode = v!),
              child: const Column(
                children: [
                  RadioListTile<_MaskMode>(
                    value: _MaskMode.none,
                    title: Text('No mask'),
                  ),
                  RadioListTile<_MaskMode>(
                    value: _MaskMode.exact,
                    title: Text('ParselyMasks exact map'),
                    subtitle: Text(
                      "'+2348068989116' → 'My Contact', "
                      "'rea…@gmail.com' → '•••@example.com'",
                    ),
                  ),
                  RadioListTile<_MaskMode>(
                    value: _MaskMode.partialLast,
                    title: Text('maskBuilder: partialLast (phone, keep 4)'),
                    subtitle: Text(
                      'ParselyMaskBuilders.partialLast(type: phone, keepLast: 4)',
                    ),
                  ),
                  RadioListTile<_MaskMode>(
                    value: _MaskMode.legacy,
                    title: Text('Legacy ParselyMask (deprecated)'),
                    subtitle:
                        Text('Kept only to show the old API still works.'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Parsely(
              text: _sampleText,
              style: TextStyle(color: scheme.onSurface, fontSize: 16),
              parsedStyle: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
              options: _options,
              masks: _masks,
              maskBuilder: _maskBuilder,
              // ignore: deprecated_member_use
              mask: _legacyMask,
              onTap: _handleTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _headlessSection(ColorScheme scheme) {
    final entities = ParselyParser.extract(
      _sampleText,
      options: _options,
      masks: _masks,
      maskBuilder: _maskBuilder,
    );
    final replaced = ParselyParser.replace(
      _sampleText,
      options: _options,
      masks: _masks,
      maskBuilder: _maskBuilder,
    );
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '5 · Headless ParselyParser.extract()',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'Pure-Dart, no widgets. Uses the same options + mask as above.',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            Text(
              'replace(): $replaced',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 8),
            if (entities.isEmpty)
              const Text('No entities (all toggles off?).')
            else
              ...entities.map((e) => ListTile(
                    leading: Chip(label: Text(e.type.name)),
                    title: Text(
                      '${e.parsed}  →  ${e.displayText}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                        'offsets ${e.start}-${e.end} · uri=${e.uri ?? '—'}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Copy original',
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copy(e.parsed),
                        ),
                        IconButton(
                          tooltip: 'Launch preview',
                          icon: const Icon(Icons.open_in_new),
                          onPressed: () => _launchPreview(e),
                        ),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _selectableSection(ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '6 · SelectableParsely (long-press to select/copy)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'Copying a masked span copies the display text '
              '(privacy-preserving).',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            SelectableParsely(
              text: _sampleText,
              style: TextStyle(color: scheme.onSurface, fontSize: 16),
              parsedStyles: _parsedStyles,
              options: _options,
              masks: _masks,
              maskBuilder: _maskBuilder,
              onTap: _handleTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _stylesSection(ColorScheme scheme) {
    const palette = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.cyan,
      Colors.brown,
      Colors.grey,
    ];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '7 · Per-type styles (parsedStyles color picker per type)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ...ParselyType.values.map((t) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    Wrap(
                      spacing: 6,
                      children: palette.map((c) {
                        final selected = _typeColors[t] == c;
                        return ChoiceChip(
                          label: const Text('Aa'),
                          selected: selected,
                          backgroundColor: c.withValues(alpha: 0.25),
                          selectedColor: c.withValues(alpha: 0.6),
                          onSelected: (_) => setState(() => _typeColors[t] = c),
                        );
                      }).toList(),
                    ),
                  ],
                )),
            const SizedBox(height: 8),
            Parsely(
              text: _sampleText,
              style: TextStyle(color: scheme.onSurface, fontSize: 16),
              parsedStyles: _parsedStyles,
              options: _options,
              onTap: _handleTap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _samplesSection(ColorScheme scheme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '8 · RTL + unicode hashtag samples',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text('RTL (Arabic):',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Parsely(
              text: _rtlSample,
              textDirection: TextDirection.rtl,
              style: TextStyle(color: scheme.onSurface, fontSize: 16),
              parsedStyle: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
              options: _options,
              onTap: _handleTap,
            ),
            const SizedBox(height: 12),
            const Text('Unicode hashtags:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Parsely(
              text: _unicodeSample,
              style: TextStyle(color: scheme.onSurface, fontSize: 16),
              parsedStyle: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.bold,
              ),
              options: _options,
              onTap: _handleTap,
            ),
          ],
        ),
      ),
    );
  }
}
