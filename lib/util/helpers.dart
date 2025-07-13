import 'dart:core';

import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

const trueValues = {'yes', 'true'};

const dateFormatPatterns = [
  'EEE, d MMM yyyy HH:mm:ss Z',
];

final parsers = [
  DateTime.parse,
  ...dateFormatPatterns
      .map((pattern) => DateFormat(pattern))
      .map((parser) => parser.parse),
];

XmlElement? findElementOrNull(XmlElement element, String name,
    {String? namespace}) {
  try {
    return element.findAllElements(name, namespace: namespace).first;
  } on StateError {
    return null;
  }
}

List<XmlElement>? findAllDirectElementsOrNull(XmlElement element, String name,
    {String? namespace}) {
  try {
    return element.findElements(name, namespace: namespace).toList();
  } on StateError {
    return null;
  }
}

bool? parseBoolLiteral(XmlElement element, String tagName) {
  final v = findElementOrNull(element, tagName)?.innerText.toLowerCase().trim();
  if (v == null) {
    return null;
  }
  return trueValues.contains(v);
}

bool? parseBool(String? v) {
  if (v == null) {
    return null;
  }
  return trueValues.contains(v);
}

extension SafeParseDateTime on DateTime {
  static DateTime? safeParse(String? str) {
    final trimmedDate = str?.trim();
    if (trimmedDate == null || trimmedDate.isEmpty) {
      return null;
    }

    for (final parser in parsers) {
      try {
        return parser(trimmedDate);
      } catch (_) {}
    }

    return null;
  }
}

DateTime? parseDateTime(String? dateTimeString) {
  if (dateTimeString == null) {
    return null;
  }
  return DateTime.tryParse(dateTimeString);
}

int? parseInt(String? intString) {
  if (intString == null) {
    return null;
  }
  return int.tryParse(intString);
}
