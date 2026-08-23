import 'dart:core';

import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

const trueValues = {'yes', 'true'};

final _rfc822DateFormat = DateFormat('EEE, d MMM yyyy HH:mm:ss');
final _rfc822NamedTimezoneDateFormat = DateFormat(
  'EEE, d MMM yyyy HH:mm:ss Z',
);
final _rfc822NumericTimezone = RegExp(
  r'^(.*\d)\s+([+-])(\d{2})(\d{2})$',
);

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

    final isoDate = DateTime.tryParse(trimmedDate);
    if (isoDate != null) {
      return isoDate;
    }

    final rfc822Match = _rfc822NumericTimezone.firstMatch(trimmedDate);
    if (rfc822Match != null) {
      try {
        final wallClock = _rfc822DateFormat.parseUtc(rfc822Match.group(1)!);
        final offset = Duration(
          hours: int.parse(rfc822Match.group(3)!),
          minutes: int.parse(rfc822Match.group(4)!),
        );
        return rfc822Match.group(2) == '+'
            ? wallClock.subtract(offset)
            : wallClock.add(offset);
      } on FormatException {
        return null;
      }
    }

    try {
      return _rfc822NamedTimezoneDateFormat.parse(trimmedDate);
    } on FormatException {
      return null;
    }
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
