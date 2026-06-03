import 'dart:convert';
import 'dart:io';

void main() {
  final Map<String, Map<String, String>> newKeys = {
    'en': {
      'select_path': 'Select your path to continue',
      'min_short': 'min',
      'journey_transfers': '⚠️ This journey has {} transfer(s)',
      'blind_assist_mode': '♿ Blind Assist Mode',
      'blind_assist_subtitle': 'Step-by-step voice guidance + haptics',
      'hint_sadat': 'Board the front of the train for a quick transfer at Sadat station.',
      'hint_shohadaa': 'Board the back of the train for a quick transfer at Shohadaa station.',
      'hint_attaba_nasser': 'Board the middle of the train to easily exit at Attaba/Nasser.',
      'hint_general_transfer': 'Position yourself in the middle of the train for an easier transfer.'
    },
    'ar': {
      'select_path': 'حدد مسار رحلتك للمتابعة',
      'min_short': 'دقيقة',
      'journey_transfers': '⚠️ هذه الرحلة تحتوي على {} محطة تبديل',
      'blind_assist_mode': '♿ وضع مساعدة المكفوفين',
      'blind_assist_subtitle': 'توجيه صوتي خطوة بخطوة + اهتزاز',
      'hint_sadat': 'اركب أول القطار للتبديل السريع في محطة السادات.',
      'hint_shohadaa': 'اركب آخر القطار لتبديل أسرع في محطة الشهداء.',
      'hint_attaba_nasser': 'اركب في منتصف القطار للنزول بسهولة في العتبة/ناصر.',
      'hint_general_transfer': 'تمركز في منتصف القطار للتبديل بشكل أسهل.'
    },
    'fr': {
      'select_path': 'Sélectionnez votre itinéraire pour continuer',
      'min_short': 'min',
      'journey_transfers': '⚠️ Ce trajet comporte {} correspondance(s)',
      'blind_assist_mode': '♿ Mode d\'assistance aux malvoyants',
      'blind_assist_subtitle': 'Guidage vocal étape par étape + haptique',
      'hint_sadat': 'Montez à l\'avant du train pour une correspondance rapide à la station Sadat.',
      'hint_shohadaa': 'Montez à l\'arrière du train pour une correspondance rapide à la station Shohadaa.',
      'hint_attaba_nasser': 'Montez au milieu du train pour sortir facilement à Attaba/Nasser.',
      'hint_general_transfer': 'Placez-vous au milieu du train pour faciliter votre correspondance.'
    },
    'de': {
      'select_path': 'Wählen Sie Ihre Route, um fortzufahren',
      'min_short': 'Min',
      'journey_transfers': '⚠️ Diese Reise hat {} Umstieg(e)',
      'blind_assist_mode': '♿ Blindenassistenz-Modus',
      'blind_assist_subtitle': 'Schritt-für-Schritt-Sprachanweisung + Haptik',
      'hint_sadat': 'Steigen Sie für einen schnellen Umstieg an der Station Sadat vorne in den Zug ein.',
      'hint_shohadaa': 'Steigen Sie für einen schnellen Umstieg an der Station Shohadaa hinten in den Zug ein.',
      'hint_attaba_nasser': 'Steigen Sie in die Mitte des Zuges ein, um an Attaba/Nasser bequem auszusteigen.',
      'hint_general_transfer': 'Positionieren Sie sich für einen leichteren Umstieg in der Mitte des Zuges.'
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
