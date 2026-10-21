import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// One entry of the Rechtspraak search feed.
class RulingSummary {
  const RulingSummary({required this.ecli, this.title = '', this.summary = ''});

  final String ecli;
  final String title;

  /// Official summary (inhoudsindicatie); "-" or empty when the court gave none.
  final String summary;

  bool get hasSummary => summary.trim().length > 40;
}

/// Court level, read from the court code of an ECLI (RB…, GH…, HR).
enum CourtLevel {
  district,
  appeal,
  supreme,
  other;

  static CourtLevel ofEcli(String ecli) {
    final parts = ecli.split(':');
    final code = parts.length > 2 ? parts[2] : '';
    if (code == 'HR') return supreme;
    if (code.startsWith('RB')) return district;
    if (code.startsWith('GH')) return appeal;
    return other;
  }
}

/// Client for Rechtspraak Open Data (free, no key, XML), throttled under 10 requests per second.
class RechtspraakClient {
  RechtspraakClient({http.Client? client, this.minInterval = const Duration(milliseconds: 120)})
      : _client = client ?? http.Client();

  final http.Client _client;
  final Duration minInterval;
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);

  static const _base = 'https://data.rechtspraak.nl/uitspraken';

  Future<String> _get(String url) async {
    final wait = _last.add(minInterval).difference(DateTime.now());
    if (!wait.isNegative) await Future<void>.delayed(wait);
    _last = DateTime.now();
    final res = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw Exception('Rechtspraak HTTP ${res.statusCode} : $url');
    return utf8.decode(res.bodyBytes, allowMalformed: true);
  }

  /// One page of criminal rulings with a full text, decided between [from] and [to].
  Future<List<RulingSummary>> searchCriminal({
    required DateTime from,
    required DateTime to,
    int offset = 0,
    int pageSize = 100,
  }) async {
    String day(DateTime d) => d.toIso8601String().substring(0, 10);
    final xml = await _get('$_base/zoeken?type=Uitspraak&return=DOC&sort=DESC'
        '&max=$pageSize&from=$offset&date=${day(from)}&date=${day(to)}'
        '&subject=http://psi.rechtspraak.nl/rechtsgebied%23strafrecht');
    return XmlDocument.parse(xml)
        .findAllElements('entry')
        .map((e) {
          String text(String name) => e.getElement(name)?.innerText.trim() ?? '';
          return RulingSummary(ecli: text('id'), title: text('title'), summary: text('summary'));
        })
        .where((r) => r.ecli.startsWith('ECLI:'))
        .toList();
  }

  /// Raw XML of one ruling (metadata, inhoudsindicatie and uitspraak).
  Future<String> fetchRulingXml(String ecli) async {
    final xml = await _get('$_base/content?id=${Uri.encodeQueryComponent(ecli)}');
    if (!xml.contains('<uitspraak')) throw Exception('No ruling text for $ecli');
    return xml;
  }
}

/// The parts of a ruling XML that the code reads itself.
class RulingXml {
  RulingXml(this.raw) : _doc = XmlDocument.parse(raw);

  final String raw;
  final XmlDocument _doc;

  XmlElement? get _uitspraak => _doc.descendantElements.where((e) => e.localName == 'uitspraak').firstOrNull;

  /// dcterms:modified, as written in the metadata.
  String? get modified => _doc.descendantElements
      .where((e) => e.localName == 'modified' && e.namespacePrefix == 'dcterms')
      .firstOrNull
      ?.innerText
      .trim();

  /// The start of the ruling text, for the pre-sort when the search gave no summary.
  String excerpt([int maxChars = 6000]) {
    final texts = _uitspraak?.descendants.whereType<XmlText>().map((t) => t.value) ?? const <String>[];
    final text = texts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.length <= maxChars ? text : text.substring(0, maxChars);
  }

  /// Plain text of the decision section (beslissing), or the end of the ruling if none is found.
  String get dictumText {
    final uitspraak = _uitspraak;
    if (uitspraak == null) return '';
    XmlElement? last;
    for (final section in uitspraak.descendantElements.where((e) => e.localName == 'section')) {
      final title = section.childElements.where((e) => e.localName == 'title').firstOrNull;
      if (section.getAttribute('role') == 'beslissing' ||
          (title != null && title.innerText.toLowerCase().contains('beslissing'))) {
        last = section;
      }
    }
    if (last != null) return last.innerText;
    final text = uitspraak.innerText;
    final i = text.toLowerCase().lastIndexOf('beslissing');
    return i >= 0 ? text.substring(i) : text;
  }
}
