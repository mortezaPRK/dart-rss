<p align="center">
  <img src="https://github.com/Flutter-Bounty-Hunters/dart-rss/assets/7259036/22439f2a-669c-48ae-a0ca-2705500a9cc2" alt="Dart RSS - RSS parser and serializer for Dart">
</p>

<p align="center">
  <a href="https://flutterbountyhunters.com" target="_blank">
    <img src="https://github.com/Flutter-Bounty-Hunters/flutter_test_robots/assets/7259036/1b19720d-3dad-4ade-ac76-74313b67a898" alt="Built by the Flutter Bounty Hunters">
  </a>
</p>

---
A dart package for parsing and generating RSS1.0, RSS2.0, and Atom feeds.

### Example
Import the package into your dart code using:
```
import 'package:dart_rss/dart_rss.dart';
```

To parse string into `RssFeed` object use:
```
var rssFeed = new RssFeed.parse(xmlString); // for parsing RSS 2.0 feed
var atomFeed = new AtomFeed.parse(xmlString); // for parsing Atom feed
var rss1Feed = new Rss1Feed.parse(xmlString); // for parsing RSS 1.0 feed
```

### Reuse the parsed XML document
For better performance when dealing with large XML documents, you can parse the XML document once and reuse it:

```dart
import 'package:xml/xml.dart';

// Parse XML once
final document = XmlDocument.parse(xmlString);

// Use the parsed document for different parsers
final rssFeed = RssFeed.parseFromXml(document);
final atomFeed = AtomFeed.parseFromXml(document);
final rss1Feed = Rss1Feed.parseFromXml(document);

// Or use the unified WebFeed parser
final webFeed = WebFeed.fromXmlDocument(document);
```

### Unified Feed Parsing & Pattern Matching (Dart 3)

For advanced use cases, you can use the new `FeedParser` helper to parse any feed (RSS 1.0, RSS 2.0, Atom, or unknown) and leverage Dart 3's pattern matching and exhaustive handling:

```dart
import 'package:dart_rss/util/feed_parser.dart';

final result = FeedParser.fromXmlString(xmlString);

switch (result) {
  case Rss1ParseResult(feed: final feed):
    print('RSS 1.0: \\${feed.title}');
  case Rss2ParseResult(feed: final feed):
    print('RSS 2.0: \\${feed.title}');
  case AtomParseResult(feed: final feed):
    print('Atom: \\${feed.title}');
  case UnknownParseResult(error: final error):
    print('Error: \\${error.reason}');
}
```

Or use the `when` method for a Freezed-style API:

```dart
final message = result.when(
  rss1: (feed) => 'RSS 1.0: \\${feed.title}',
  rss2: (feed) => 'RSS 2.0: \\${feed.title}',
  atom: (feed) => 'Atom: \\${feed.title}',
  unknown: (error) => 'Error: \\${error.reason}',
);
print(message);
```

#### Detailed Error Handling

If parsing fails, you get a `ParseError` with rich details:

```dart
if (result.isUnknown()) {
  final error = result.parseError!;
  print('Reason: \\${error.reason}');
  print('HTTP Status: \\${error.httpStatusCode}');
  print('Body: \\${error.body}');
  print('Exception: \\${error.exception}');
}
```

- Error types: `httpError`, `networkError`, `invalidXml`, `parsingError`, `unknownVersion`
- All error details are available for debugging and reporting

### Preview

**RSS**
```
feed.title
feed.description
feed.link
feed.author
feed.items
feed.image
feed.cloud
feed.categories
feed.skipDays
feed.skipHours
feed.lastBuildDate
feed.language
feed.generator
feed.copyright
feed.docs
feed.managingEditor
feed.rating
feed.webMaster
feed.ttl
feed.dc

RssItem item = feed.items.first;
item.title
item.description
item.link
item.categories
item.guid
item.pubDate
item.author
item.comments
item.source
item.media
item.enclosure
item.dc
```

**Atom**
```
feed.id
feed.title
feed.updated
feed.items
feed.links
feed.authors
feed.contributors
feed.categories
feed.generator
feed.icon
feed.logo
feed.rights
feed.subtitle

AtomItem item = feed.items.first;
item.id
item.title
item.updated
item.authors
item.links
item.categories
item.contributors
item.source
item.published
item.content
item.summary
item.rights
item.media
```

**RSS 1.0**
```
feed.title
feed.description
feed.link
feed.items
feed.image
feed.updatePeriod
feed.updateFrequency
feed.updateBase
feed.dc

Rss1Item item = feed.items.first;
item.title
item.description
item.link
item.dc
item.content
```

## Origin
This package was forked from [WebFeed](https://pub.dev/packages/webfeed).

@sudame continued work after the fork. 

In June, 2023, this package was transferred to @Flutter-Bounty-Hunters
