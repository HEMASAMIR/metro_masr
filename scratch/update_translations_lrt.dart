import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, Map<String, String>> newKeys = {
    'en': {
      'Capital Train (LRT)': 'Capital Train (LRT)',
      'Light Rail Transit': 'Light Rail Transit',
      'LRT: Adly Mansour ↔ Arts & Culture City': 'LRT: Adly Mansour ↔ Arts & Culture City',
      'Journey time: ~45 minutes': 'Journey time: ~45 minutes',
      'Ticket price: 15-25 EGP': 'Ticket price: 15-25 EGP',
    },
    'ar': {
      'Capital Train (LRT)': 'قطار العاصمة (LRT)',
      'Light Rail Transit': 'القطار الكهربائي الخفيف',
      'LRT: Adly Mansour ↔ Arts & Culture City': 'المسار: عدلي منصور ↔ مدينة الفنون والثقافة',
      'Journey time: ~45 minutes': 'مدة الرحلة: حوالي 45 دقيقة',
      'Ticket price: 15-25 EGP': 'سعر التذكرة: 15-25 جنيه',
    },
    'fr': {
      'Capital Train (LRT)': 'Train de la Capitale (LRT)',
      'Light Rail Transit': 'Train léger sur rail',
      'LRT: Adly Mansour ↔ Arts & Culture City': 'LRT: Adly Mansour ↔ Cité des Arts et de la Culture',
      'Journey time: ~45 minutes': 'Temps de trajet: ~45 minutes',
      'Ticket price: 15-25 EGP': 'Prix du billet: 15-25 EGP',
    },
    'de': {
      'Capital Train (LRT)': 'Hauptstadtzug (LRT)',
      'Light Rail Transit': 'Stadtbahn',
      'LRT: Adly Mansour ↔ Arts & Culture City': 'LRT: Adly Mansour ↔ Stadt der Künste und Kultur',
      'Journey time: ~45 minutes': 'Fahrzeit: ~45 Minuten',
      'Ticket price: 15-25 EGP': 'Ticketpreis: 15-25 EGP',
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
