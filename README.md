# Parsely

Parsely is a versatile tool designed to enhance text parsing and masking capabilities within your Flutter applications. With this package, you can effortlessly extract various entities such as links, email addresses, @mentions, hashtags, and phone numbers from text inputs. Additionally, it offers the functionality to mask these entities with customizable masks while ensuring they remain clickable for seamless user interaction.

## Key Features

1. Entity Parsing: Easily parse links, email addresses, @mentions, hashtags, and phone numbers embedded within text strings.
2. Customizable Masks: Define custom masks to obscure sensitive information such as email addresses or phone numbers while preserving their format.
3. Clickable Entities: Automatically convert parsed entities into clickable elements, enabling users to interact with them effortlessly.
4. Flexible Integration: Seamlessly integrate the parser and masker functionality into your Flutter applications with minimal configuration.
5. Performance Optimized: Engineered for optimal performance to ensure smooth operation even with large volumes of text inputs.
6. Cross-platform Compatibility: Compatible with all flutter supported platforms.

## Use Cases

1. Social Media Apps: Enhance user engagement by making @mentions and hashtags clickable within comments or posts.
2. Messaging Platforms: Improve user experience by automatically parsing and masking phone numbers and email addresses within chat conversations.
3. E-commerce Apps: Protect user privacy by masking email addresses and phone numbers while enabling clickable links for product URLs.
4. Content Sharing Apps: Facilitate seamless sharing of content by parsing and masking links within text descriptions or captions.

## Install

Install by adding this package to your `pubspec.yaml`:

```yaml
dependencies:
  binkap_parsely: <latest>
```

#

```bash
flutter pub add binkap_parsely
```

## Usage

To use this package, add `binkap_parsely` as a [dependency in your pubspec.yaml file](https://pub.dev/packages/binkap_parsely/).

to `/example` folder.

```dart
import 'package:binkap_parsely/binkap_parsely.dart';

Parsely(
      text:
          'Visit me https://binkap.com, or you could send me an email at rea.desert.tiger@gmail.com, Supposedly you prefer calls reach me at +2348068989116 or simply use #binkap on twitter',
      textAlign: TextAlign.center,
      options: ParselyOptions( //Optional
        parseMentionTag: false, // Default true
        humanize: true, // Default true
        parsePhone: true, // Default true
        parseHashTag: true, // Default true
        parseEmail: true, // Default true
        parseLink: true, // Default true
      ),
      mask: ParselyMask( // Optional
        matches: [
          '+2348068989116',
        ],
        masks: [
          'My Contact',
        ],
      ),
      style: const TextStyle( // Styling for unmatched text
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'DancingScript',
      ),
      parsedStyle: const TextStyle( // Styling for Matched text
        color: Color.fromARGB(255, 33, 243, 86),
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: 'DancingScript',
      ),
      onTap: (element) { // Function to be invoked when matched text is clicked
        switch (element.type) {
          case ParselyType.link:
            print('Do something with the link: ${element.parsed}');
            break;
          case ParselyType.email:
            print('Do Something with the email: ${element.parsed}');
            break;
          case ParselyType.phone:
            print('Do Something with the phone number: ${element.parsed}');
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
    );
```

## Dictionary

#### ParselyElement

| Parameter | Type     | Description                                          |
| :-------- | :------- | :--------------------------------------------------- |
| `type`    | `ParselyType`   | the parsed text either url, email, phone number, hashtag or @mention      |
| `parsed`    | `String` | value the parsed text holds                                 |
