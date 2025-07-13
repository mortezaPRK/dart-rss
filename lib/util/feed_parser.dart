import 'package:xml/xml.dart';
import 'package:http/http.dart' as http;
import 'package:dart_rss/domain/dart_rss.dart';
import 'package:dart_rss/domain/rss_feed.dart';
import 'package:dart_rss/domain/rss1_feed.dart';
import 'package:dart_rss/domain/atom_feed.dart';

enum ParseErrorType {
  httpError,
  networkError,
  invalidXml,
  parsingError,
  unknownVersion,
}

/// Data class to encapsulate parsing error details
class ParseError {
  const ParseError._({
    required this.reason,
    this.httpStatusCode,
    this.body,
    this.exception,
  });

  factory ParseError.httpError(http.Response response) {
    return ParseError._(
      reason: ParseErrorType.httpError,
      httpStatusCode: response.statusCode,
      body: response.body,
    );
  }

  factory ParseError.networkError(Object exception) {
    return ParseError._(
      reason: ParseErrorType.networkError,
      exception: exception,
    );
  }

  factory ParseError.invalidXml(Object exception) {
    return ParseError._(
      reason: ParseErrorType.invalidXml,
      exception: exception,
    );
  }

  factory ParseError.parsingError(Object exception) {
    return ParseError._(
      reason: ParseErrorType.parsingError,
      exception: exception,
    );
  }

  factory ParseError.unknownVersion() {
    return const ParseError._(
      reason: ParseErrorType.unknownVersion,
    );
  }

  final ParseErrorType reason;
  final int? httpStatusCode;
  final String? body;
  final Object? exception;

  @override
  String toString() {
    final parts = [reason.name];

    if (httpStatusCode != null) {
      parts.add('HTTP Status: $httpStatusCode');
    }

    if (body != null && body!.isNotEmpty) {
      parts.add(
          'Body: ${body!.length > 100 ? '${body!.substring(0, 100)}...' : body}');
    }

    if (exception != null) {
      parts.add('Exception: ${exception.toString()}');
    }

    return parts.join(' | ');
  }
}

/// Union type for RSS feed parsing results
abstract class FeedParseResult {
  const FeedParseResult();

  /// Pattern matching method similar to Freezed's when()
  T when<T>({
    required T Function(Rss1Feed feed) rss1,
    required T Function(RssFeed feed) rss2,
    required T Function(AtomFeed feed) atom,
    required T Function(ParseError error) unknown,
  });

  /// Pattern matching with switch statement
  bool isRss1() => false;
  bool isRss2() => false;
  bool isAtom() => false;
  bool isUnknown() => false;

  /// Get the feed data if available
  Rss1Feed? get rss1Feed => null;
  RssFeed? get rss2Feed => null;
  AtomFeed? get atomFeed => null;
  ParseError? get parseError => null;
}

class Rss1ParseResult extends FeedParseResult {
  const Rss1ParseResult(this.feed);

  final Rss1Feed feed;

  @override
  T when<T>({
    required T Function(Rss1Feed feed) rss1,
    required T Function(RssFeed feed) rss2,
    required T Function(AtomFeed feed) atom,
    required T Function(ParseError error) unknown,
  }) {
    return rss1(feed);
  }

  @override
  bool isRss1() => true;

  @override
  Rss1Feed? get rss1Feed => feed;
}

class Rss2ParseResult extends FeedParseResult {
  const Rss2ParseResult(this.feed);

  final RssFeed feed;

  @override
  T when<T>({
    required T Function(Rss1Feed feed) rss1,
    required T Function(RssFeed feed) rss2,
    required T Function(AtomFeed feed) atom,
    required T Function(ParseError error) unknown,
  }) {
    return rss2(feed);
  }

  @override
  bool isRss2() => true;

  @override
  RssFeed? get rss2Feed => feed;
}

class AtomParseResult extends FeedParseResult {
  const AtomParseResult(this.feed);

  final AtomFeed feed;

  @override
  T when<T>({
    required T Function(Rss1Feed feed) rss1,
    required T Function(RssFeed feed) rss2,
    required T Function(AtomFeed feed) atom,
    required T Function(ParseError error) unknown,
  }) {
    return atom(feed);
  }

  @override
  bool isAtom() => true;

  @override
  AtomFeed? get atomFeed => feed;
}

class UnknownParseResult extends FeedParseResult {
  const UnknownParseResult(this.error);

  final ParseError error;

  @override
  T when<T>({
    required T Function(Rss1Feed feed) rss1,
    required T Function(RssFeed feed) rss2,
    required T Function(AtomFeed feed) atom,
    required T Function(ParseError error) unknown,
  }) {
    return unknown(error);
  }

  @override
  bool isUnknown() => true;

  @override
  ParseError? get parseError => error;
}

/// Helper class for parsing RSS feeds with pattern matching support
class FeedParser {
  /// Parse feed from URL
  static Future<FeedParseResult> fromUrl(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return fromXmlString(response.body);
      } else {
        return UnknownParseResult(ParseError.httpError(response));
      }
    } catch (e) {
      return UnknownParseResult(ParseError.networkError(e));
    }
  }

  /// Parse feed from XML string
  static FeedParseResult fromXmlString(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      return fromXmlDocument(document);
    } catch (e) {
      return UnknownParseResult(ParseError.invalidXml(e));
    }
  }

  /// Parse feed from XML document
  static FeedParseResult fromXmlDocument(XmlDocument document) {
    try {
      final rssVersion = detectRssVersionFromDocument(document);

      switch (rssVersion) {
        case RssVersion.rss1:
          final rss1Feed = Rss1Feed.parseFromXml(document);
          return Rss1ParseResult(rss1Feed);
        case RssVersion.rss2:
          final rss2Feed = RssFeed.parseFromXml(document);
          return Rss2ParseResult(rss2Feed);
        case RssVersion.atom:
          final atomFeed = AtomFeed.parseFromXml(document);
          return AtomParseResult(atomFeed);
        case RssVersion.unknown:
          return UnknownParseResult(ParseError.unknownVersion());
      }
    } catch (e) {
      return UnknownParseResult(ParseError.parsingError(e));
    }
  }

  /// Detect RSS version from XML document
  static RssVersion detectRssVersionFromDocument(XmlDocument document) {
    if (document.findAllElements('rdf:RDF').isNotEmpty) {
      return RssVersion.rss1;
    }

    if (document
            .findAllElements('rss')
            .firstOrNull
            ?.getAttribute('version')
            ?.contains('2') ==
        true) {
      return RssVersion.rss2;
    }

    if (document
            .findAllElements('feed')
            .firstOrNull
            ?.getAttribute('xmlns')
            ?.toLowerCase()
            .contains('atom') ==
        true) {
      return RssVersion.atom;
    }

    return RssVersion.unknown;
  }
}
