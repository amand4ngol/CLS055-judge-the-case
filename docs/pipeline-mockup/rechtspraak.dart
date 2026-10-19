import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// One entry of the Rechtspraak search feed.
class RulingSummary {
  RulingSummary({required this.ecli, required this.title, required this.summary});

  final String ecli;
  final String title;
  final String summary;
}

/// Minimal client for Rechtspraak Open Data (free, no key, returns XML).
class RechtspraakClient {
  RechtspraakClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const _base = 'https://data.rechtspraak.nl/uitspraken';

  /// Raw XML of one ruling (metadata + inhoudsindicatie + uitspraak).
  Future<String> fetchRulingXml(String ecli) async {
    final uri = Uri.parse('$_base/content?id=${Uri.encodeQueryComponent(ecli)}');
    final res = await _client.get(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Rechtspraak HTTP ${res.statusCode} pour $ecli');
    }
    final xml = utf8.decode(res.bodyBytes, allowMalformed: true);
    if (!xml.contains('<uitspraak')) {
      throw Exception('Pas de texte de décision (<uitspraak>) pour $ecli');
    }
    return xml;
  }

  /// Latest published criminal rulings that have a full text.
  Future<List<RulingSummary>> recentCriminalRulings({int max = 30}) async {
    // The legal-area URI is case-sensitive and its '#' must be sent as %23.
    final uri = Uri.parse('$_base/zoeken?type=Uitspraak&return=DOC&sort=DESC&max=$max'
        '&subject=http://psi.rechtspraak.nl/rechtsgebied%23strafrecht');
    final res = await _client.get(uri).timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) {
      throw Exception('Rechtspraak HTTP ${res.statusCode} (recherche)');
    }
    final doc = XmlDocument.parse(utf8.decode(res.bodyBytes, allowMalformed: true));
    return doc
        .findAllElements('entry')
        .map((e) {
          String text(String name) => e.getElement(name)?.innerText.trim() ?? '';
          return RulingSummary(ecli: text('id'), title: text('title'), summary: text('summary'));
        })
        .where((r) => r.ecli.startsWith('ECLI:'))
        .toList();
  }
}

/// Helpers to read the parts of a ruling XML that the code checks itself.
class RulingXml {
  RulingXml(this.raw) : _doc = XmlDocument.parse(raw);

  final String raw;
  final XmlDocument _doc;

  /// dcterms:modified, as written in the metadata.
  String? get modified {
    for (final e in _doc.descendantElements) {
      if (e.localName == 'modified' && e.namespacePrefix == 'dcterms') {
        return e.innerText.trim();
      }
    }
    return null;
  }

  /// Plain text of the decision ("beslissing") section, i.e. the dictum.
  /// Falls back to the whole ruling text when no such section is found.
  String get dictumText {
    final uitspraak = _doc.descendantElements.where((e) => e.localName == 'uitspraak').firstOrNull;
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
