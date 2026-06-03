import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, Map<String, String>> newKeys = {
    'en': {
      'East Nile Monorail': 'East Nile Monorail',
      'Monorail: Stadium ↔ City of Justice': 'Monorail: Stadium ↔ City of Justice',
      'Transfer: Stadium Station (Line 3)': 'Transfer: Stadium Station (Line 3)',
      'Capital Transport': 'Capital Transport',
      'LRT & Monorail': 'LRT & Monorail',
      'Transfer: Adly Mansour (Line 3)': 'Transfer: Adly Mansour (Line 3)',
    },
    'ar': {
      'East Nile Monorail': 'مونوريل شرق النيل',
      'Monorail: Stadium ↔ City of Justice': 'المسار: الاستاد ↔ مدينة العدالة',
      'Transfer: Stadium Station (Line 3)': 'التبديل: من محطة الاستاد (الخط الثالث)',
      'Capital Transport': 'مواصلات العاصمة',
      'LRT & Monorail': 'LRT والمونوريل',
      'Transfer: Adly Mansour (Line 3)': 'التبديل: من محطة عدلي منصور (الخط الثالث)',
    },
    'fr': {
      'East Nile Monorail': 'Monorail du Nil Est',
      'Monorail: Stadium ↔ City of Justice': 'Monorail: Stade ↔ Cité de la Justice',
      'Transfer: Stadium Station (Line 3)': 'Transfert: Station Stade (Ligne 3)',
      'Capital Transport': 'Transport de la Capitale',
      'LRT & Monorail': 'LRT et Monorail',
      'Transfer: Adly Mansour (Line 3)': 'Transfert: Adly Mansour (Ligne 3)',
    },
    'de': {
      'East Nile Monorail': 'Ost-Nil-Monorail',
      'Monorail: Stadium ↔ City of Justice': 'Monorail: Stadion ↔ Stadt der Justiz',
      'Transfer: Stadium Station (Line 3)': 'Umstieg: Station Stadion (Linie 3)',
      'Capital Transport': 'Hauptstadt-Verkehr',
      'LRT & Monorail': 'LRT & Monorail',
      'Transfer: Adly Mansour (Line 3)': 'Umstieg: Adly Mansour (Linie 3)',
    }
  };

  final languages = ['en', 'ar', 'fr', 'de'];
  final path = 'assets/translations';

  for (final lang in languages) {
    final file = File('$path/$lang.json');
    if (file.existsSync()) {
      final content = file.readAsStringSync();
      final Map<String, dynamic> json = jsonDecode(content);
      
      final keysToAdd = newKeys[lang]!;
      for (final entry in keysToAdd.entries) {
        json[entry.key] = entry.value;
      }
      
      final encoder = JsonEncoder.withIndent('  ');
      file.writeAsStringSync(encoder.convert(json));
      print('Updated $lang.json');
    }
  }
}
