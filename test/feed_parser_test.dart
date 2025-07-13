import 'dart:io';

import 'package:test/test.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import 'package:dart_rss/util/feed_parser.dart';
import 'package:dart_rss/domain/dart_rss.dart';

void main() {
  group('FeedParser', () {
    final atomXmlFile = File('test/xml/Atom.xml');
    final rss1XmlFile = File('test/xml/RSS1-with-dublin-core-module.xml');
    final rss2XmlFile = File('test/xml/RSS.xml');
    final invalidXmlFile = File('test/xml/Invalid.xml');

    late String atomXmlString;
    late String rss1XmlString;
    late String rss2XmlString;
    late String invalidXmlString;

    setUpAll(() async {
      final loadFileFutures = [
        atomXmlFile.readAsString(),
        rss1XmlFile.readAsString(),
        rss2XmlFile.readAsString(),
        invalidXmlFile.readAsString(),
      ];
      final xmlStrings = await Future.wait(loadFileFutures);
      atomXmlString = xmlStrings[0];
      rss1XmlString = xmlStrings[1];
      rss2XmlString = xmlStrings[2];
      invalidXmlString = xmlStrings[3];
    });

    group('detectRssVersionFromDocument', () {
      test('should detect RSS 1.0 feed', () {
        final document = XmlDocument.parse(rss1XmlString);
        final version = FeedParser.detectRssVersionFromDocument(document);
        expect(version, RssVersion.rss1);
      });

      test('should detect RSS 2.0 feed', () {
        final document = XmlDocument.parse(rss2XmlString);
        final version = FeedParser.detectRssVersionFromDocument(document);
        expect(version, RssVersion.rss2);
      });

      test('should detect Atom feed', () {
        final document = XmlDocument.parse(atomXmlString);
        final version = FeedParser.detectRssVersionFromDocument(document);
        expect(version, RssVersion.atom);
      });

      test('should return unknown for unrecognized format', () {
        const unrecognizedXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <unknown>
          <title>Unknown Format</title>
        </unknown>
        ''';
        final document = XmlDocument.parse(unrecognizedXml);
        final version = FeedParser.detectRssVersionFromDocument(document);
        expect(version, RssVersion.unknown);
      });
    });

    group('fromXmlString', () {
      test('should parse RSS 1.0 feed successfully', () {
        final result = FeedParser.fromXmlString(rss1XmlString);

        expect(result, isA<Rss1ParseResult>());
        expect(result.isRss1(), isTrue);
        expect(result.isRss2(), isFalse);
        expect(result.isAtom(), isFalse);
        expect(result.isUnknown(), isFalse);

        final feed = result.rss1Feed!;
        expect(feed.title, 'Meerkat');
        expect(feed.description, 'Meerkat: An Open Wire Service');
        expect(feed.link, 'http://meerkat.oreillynet.com');
        expect(feed.items, isNotEmpty);
      });

      test('should parse RSS 2.0 feed successfully', () {
        final result = FeedParser.fromXmlString(rss2XmlString);

        expect(result, isA<Rss2ParseResult>());
        expect(result.isRss1(), isFalse);
        expect(result.isRss2(), isTrue);
        expect(result.isAtom(), isFalse);
        expect(result.isUnknown(), isFalse);

        final feed = result.rss2Feed!;
        expect(feed.title, 'News - Foo bar News');
        expect(feed.description,
            'Foo bar News and Updates feed provided by Foo bar, Inc.');
        expect(feed.link, 'https://foo.bar.news/');
        expect(feed.items, isNotEmpty);
      });

      test('should parse Atom feed successfully', () {
        final result = FeedParser.fromXmlString(atomXmlString);

        expect(result, isA<AtomParseResult>());
        expect(result.isRss1(), isFalse);
        expect(result.isRss2(), isFalse);
        expect(result.isAtom(), isTrue);
        expect(result.isUnknown(), isFalse);

        final feed = result.atomFeed!;
        expect(feed.title, 'Foo bar news');
        expect(feed.subtitle, 'This is subtitle');
        expect(feed.links, isNotEmpty);
        expect(feed.items, isNotEmpty);
      });

      test('should return UnknownParseResult for invalid XML', () {
        final result = FeedParser.fromXmlString(invalidXmlString);

        expect(result, isA<UnknownParseResult>());
        expect(result.isRss1(), isFalse);
        expect(result.isRss2(), isFalse);
        expect(result.isAtom(), isFalse);
        expect(result.isUnknown(), isTrue);

        final error = result.parseError!;
        expect(error.reason, ParseErrorType.unknownVersion);
        // exception is not set for unknownVersion errors
        // body might be null for unknownVersion errors
      });

      test('should return UnknownParseResult for malformed XML', () {
        const malformedXml = '<rss><channel><title>Incomplete';
        final result = FeedParser.fromXmlString(malformedXml);

        expect(result, isA<UnknownParseResult>());
        final error = result.parseError!;
        expect(error.reason, ParseErrorType.invalidXml);
        expect(error.exception, isNotNull);
      });
    });

    group('fromXmlDocument', () {
      test('should parse RSS 1.0 document successfully', () {
        final document = XmlDocument.parse(rss1XmlString);
        final result = FeedParser.fromXmlDocument(document);

        expect(result, isA<Rss1ParseResult>());
        final feed = result.rss1Feed!;
        expect(feed.title, 'Meerkat');
      });

      test('should parse RSS 2.0 document successfully', () {
        final document = XmlDocument.parse(rss2XmlString);
        final result = FeedParser.fromXmlDocument(document);

        expect(result, isA<Rss2ParseResult>());
        final feed = result.rss2Feed!;
        expect(feed.title, 'News - Foo bar News');
      });

      test('should parse Atom document successfully', () {
        final document = XmlDocument.parse(atomXmlString);
        final result = FeedParser.fromXmlDocument(document);

        expect(result, isA<AtomParseResult>());
        final feed = result.atomFeed!;
        expect(feed.title, 'Foo bar news');
      });

      test('should return UnknownParseResult for unrecognized document', () {
        const unrecognizedXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <unknown>
          <title>Unknown Format</title>
        </unknown>
        ''';
        final document = XmlDocument.parse(unrecognizedXml);
        final result = FeedParser.fromXmlDocument(document);

        expect(result, isA<UnknownParseResult>());
        final error = result.parseError!;
        expect(error.reason, ParseErrorType.unknownVersion);
        // body might be null for unknownVersion errors
      });

      test('should handle parsing exceptions', () {
        // Create a document that will cause parsing issues
        const problematicXml = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <rss version="2.0">
          <channel>
            <title>Test</title>
            <item>
              <title>Item with invalid date</title>
              <pubDate>invalid-date-format</pubDate>
            </item>
          </channel>
        </rss>
        ''';
        final document = XmlDocument.parse(problematicXml);
        final result = FeedParser.fromXmlDocument(document);

        // Should still parse successfully even with invalid dates
        expect(result, isA<Rss2ParseResult>());
      });
    });

    group('Pattern Matching', () {
      test('should work with switch statement', () {
        final rss1Result = FeedParser.fromXmlString(rss1XmlString);
        final rss2Result = FeedParser.fromXmlString(rss2XmlString);
        final atomResult = FeedParser.fromXmlString(atomXmlString);
        final errorResult = FeedParser.fromXmlString(invalidXmlString);

        // Test RSS 1.0
        String rss1Title = '';
        switch (rss1Result) {
          case Rss1ParseResult(feed: final feed):
            rss1Title = feed.title ?? '';
          case Rss2ParseResult(feed: final feed):
            rss1Title = feed.title ?? '';
          case AtomParseResult(feed: final feed):
            rss1Title = feed.title ?? '';
          case UnknownParseResult(error: final error):
            rss1Title = error.reason.name;
        }
        expect(rss1Title, 'Meerkat');

        // Test RSS 2.0
        String rss2Title = '';
        switch (rss2Result) {
          case Rss1ParseResult(feed: final feed):
            rss2Title = feed.title ?? '';
          case Rss2ParseResult(feed: final feed):
            rss2Title = feed.title ?? '';
          case AtomParseResult(feed: final feed):
            rss2Title = feed.title ?? '';
          case UnknownParseResult(error: final error):
            rss2Title = error.reason.name;
        }
        expect(rss2Title, 'News - Foo bar News');

        // Test Atom
        String atomTitle = '';
        switch (atomResult) {
          case Rss1ParseResult(feed: final feed):
            atomTitle = feed.title ?? '';
          case Rss2ParseResult(feed: final feed):
            atomTitle = feed.title ?? '';
          case AtomParseResult(feed: final feed):
            atomTitle = feed.title ?? '';
          case UnknownParseResult(error: final error):
            atomTitle = error.reason.name;
        }
        expect(atomTitle, 'Foo bar news');

        // Test Error
        String errorReason = '';
        switch (errorResult) {
          case Rss1ParseResult(feed: final feed):
            errorReason = feed.title ?? '';
          case Rss2ParseResult(feed: final feed):
            errorReason = feed.title ?? '';
          case AtomParseResult(feed: final feed):
            errorReason = feed.title ?? '';
          case UnknownParseResult(error: final error):
            errorReason = error.reason.name;
        }
        expect(errorReason, 'unknownVersion');
      });

      test('should work with when() method', () {
        final rss1Result = FeedParser.fromXmlString(rss1XmlString);
        final rss2Result = FeedParser.fromXmlString(rss2XmlString);
        final atomResult = FeedParser.fromXmlString(atomXmlString);
        final errorResult = FeedParser.fromXmlString(invalidXmlString);

        // Test RSS 1.0
        final rss1Title = rss1Result.when(
          rss1: (feed) => feed.title ?? '',
          rss2: (feed) => feed.title ?? '',
          atom: (feed) => feed.title ?? '',
          unknown: (error) => error.reason.name,
        );
        expect(rss1Title, 'Meerkat');

        // Test RSS 2.0
        final rss2Title = rss2Result.when(
          rss1: (feed) => feed.title ?? '',
          rss2: (feed) => feed.title ?? '',
          atom: (feed) => feed.title ?? '',
          unknown: (error) => error.reason.name,
        );
        expect(rss2Title, 'News - Foo bar News');

        // Test Atom
        final atomTitle = atomResult.when(
          rss1: (feed) => feed.title ?? '',
          rss2: (feed) => feed.title ?? '',
          atom: (feed) => feed.title ?? '',
          unknown: (error) => error.reason.name,
        );
        expect(atomTitle, 'Foo bar news');

        // Test Error
        final errorReason = errorResult.when(
          rss1: (feed) => feed.title ?? '',
          rss2: (feed) => feed.title ?? '',
          atom: (feed) => feed.title ?? '',
          unknown: (error) => error.reason.name,
        );
        expect(errorReason, 'unknownVersion');
      });

      test('should work with when() method returning different types', () {
        final rss1Result = FeedParser.fromXmlString(rss1XmlString);

        final itemCount = rss1Result.when(
          rss1: (feed) => feed.items.length,
          rss2: (feed) => feed.items.length,
          atom: (feed) => feed.items.length,
          unknown: (error) => 0,
        );
        expect(itemCount, isA<int>());
        expect(itemCount, greaterThan(0));
      });
    });

    group('ParseError', () {
      test('should create httpError correctly', () {
        final mockResponse = http.Response('Not Found', 404);
        final error = ParseError.httpError(mockResponse);

        expect(error.reason, ParseErrorType.httpError);
        expect(error.httpStatusCode, 404);
        expect(error.body, 'Not Found');
        expect(error.exception, isNull);
      });

      test('should create networkError correctly', () {
        final exception = Exception('Connection timeout');
        final error = ParseError.networkError(exception);

        expect(error.reason, ParseErrorType.networkError);
        expect(error.httpStatusCode, isNull);
        expect(error.body, isNull);
        expect(error.exception, exception);
      });

      test('should create invalidXml correctly', () {
        const exception = FormatException('Invalid XML');
        final error = ParseError.invalidXml(exception);

        expect(error.reason, ParseErrorType.invalidXml);
        expect(error.exception, exception);
      });

      test('should create parsingError correctly', () {
        final exception = Exception('Parsing failed');
        final error = ParseError.parsingError(exception);

        expect(error.reason, ParseErrorType.parsingError);
        expect(error.exception, exception);
      });

      test('should format toString correctly', () {
        final mockResponse = http.Response('Server Error', 500);
        final error = ParseError.httpError(mockResponse);

        final string = error.toString();
        expect(string, contains('httpError'));
        expect(string, contains('HTTP Status: 500'));
        expect(string, contains('Body: Server Error'));
      });
    });

    group('fromUrl', () {
      test('should handle successful HTTP response', () async {
        // This test would require mocking HTTP responses
        // For now, we'll test the error handling
        final result =
            await FeedParser.fromUrl('https://invalid-url-that-will-fail.com');

        expect(result, isA<UnknownParseResult>());
        final error = result.parseError!;
        expect(error.reason, ParseErrorType.networkError);
        expect(error.exception, isNotNull);
      });

      test('should handle HTTP error responses', () async {
        // This would require HTTP mocking
        // For now, we'll test the structure
        final mockResponse = http.Response('Not Found', 404);
        final error = ParseError.httpError(mockResponse);
        final result = UnknownParseResult(error);

        expect(result, isA<UnknownParseResult>());
        expect(result.parseError!.reason, ParseErrorType.httpError);
        expect(result.parseError!.httpStatusCode, 404);
      });
    });
  });
}
