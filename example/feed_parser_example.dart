import 'package:dart_rss/util/feed_parser.dart';

void main() async {
  // Example 1: Parse from URL
  print('=== Parsing from URL ===');
  final urlResult =
      await FeedParser.fromUrl('https://feeds.bbci.co.uk/news/rss.xml');

  // Pattern matching with switch statement
  switch (urlResult) {
    case Rss1ParseResult(feed: final feed):
      print('RSS 1.0 Feed: ${feed.title}');
      print('Items: ${feed.items.length}');
    case Rss2ParseResult(feed: final feed):
      print('RSS 2.0 Feed: ${feed.title}');
      print('Items: ${feed.items.length}');
    case AtomParseResult(feed: final feed):
      print('Atom Feed: ${feed.title}');
      print('Items: ${feed.items.length}');
    case UnknownParseResult(error: final error):
      print('Error: ${error.reason}');
      if (error.httpStatusCode != null) {
        print('HTTP Status: ${error.httpStatusCode}');
      }
      if (error.exception != null) {
        print('Exception: ${error.exception}');
      }
  }

  // Example 2: Using the when() method (similar to Freezed)
  print('\n=== Using when() method ===');
  final message = urlResult.when(
    rss1: (feed) => 'RSS 1.0: ${feed.title}',
    rss2: (feed) => 'RSS 2.0: ${feed.title}',
    atom: (feed) => 'Atom: ${feed.title}',
    unknown: (error) => 'Error: ${error.reason}',
  );
  print(message);

  // Example 3: Parse from XML string
  print('\n=== Parsing from XML string ===');
  const xmlString = '''
<?xml version="1.0" encoding="UTF-8"?>
<rss version="2.0">
  <channel>
    <title>Example RSS Feed</title>
    <description>An example RSS feed</description>
    <item>
      <title>First Item</title>
      <description>This is the first item</description>
    </item>
  </channel>
</rss>
''';

  final xmlResult = FeedParser.fromXmlString(xmlString);

  xmlResult.when(
    rss1: (feed) => print('RSS 1.0 detected'),
    rss2: (feed) => print('RSS 2.0 detected: ${feed.title}'),
    atom: (feed) => print('Atom detected'),
    unknown: (error) => print('Error: ${error.reason}'),
  );

  // Example 4: Error handling with detailed error information
  print('\n=== Error handling ===');
  final errorResult = FeedParser.fromXmlString('invalid xml');

  if (errorResult.isUnknown()) {
    final error = errorResult.parseError!;
    print('Error Details:');
    print('  Reason: ${error.reason}');
    if (error.exception != null) {
      print('  Exception: ${error.exception}');
    }
    if (error.body != null) {
      print('  Body: ${error.body}');
    }
  }

  // Example 5: Type checking
  print('\n=== Type checking ===');
  if (xmlResult.isRss2()) {
    final feed = xmlResult.rss2Feed!;
    print('Confirmed RSS 2.0 feed with ${feed.items.length} items');
  }
}

/// Example function showing different pattern matching approaches
void demonstratePatternMatching(FeedParseResult result) {
  // Approach 1: Switch statement (Dart 3.0+)
  switch (result) {
    case Rss1ParseResult(feed: final feed):
      print('Processing RSS 1.0 feed: ${feed.title}');
    case Rss2ParseResult(feed: final feed):
      print('Processing RSS 2.0 feed: ${feed.title}');
    case AtomParseResult(feed: final feed):
      print('Processing Atom feed: ${feed.title}');
    case UnknownParseResult(error: final error):
      print('Error processing feed: ${error.reason}');
      if (error.httpStatusCode != null) {
        print('HTTP Status Code: ${error.httpStatusCode}');
      }
  }

  // Approach 2: When method (Freezed-style)
  final status = result.when(
    rss1: (feed) => 'RSS 1.0: ${feed.items.length} items',
    rss2: (feed) => 'RSS 2.0: ${feed.items.length} items',
    atom: (feed) => 'Atom: ${feed.items.length} items',
    unknown: (error) => 'Error: ${error.reason}',
  );
  print(status);
}

/// Example function showing detailed error handling
void handleParseError(FeedParseResult result) {
  result.when(
    rss1: (feed) => print('Successfully parsed RSS 1.0 feed'),
    rss2: (feed) => print('Successfully parsed RSS 2.0 feed'),
    atom: (feed) => print('Successfully parsed Atom feed'),
    unknown: (error) {
      print('Parse Error Details:');
      print('  Reason: ${error.reason}');

      if (error.httpStatusCode != null) {
        print('  HTTP Status: ${error.httpStatusCode}');
      }

      if (error.exception != null) {
        print('  Exception: ${error.exception}');
      }

      if (error.body != null) {
        print('  Response Body: ${error.body}');
      }
    },
  );
}
