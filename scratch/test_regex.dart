void main() {
  String text = "isAr ? 'الرئيسية' : 'Home'";
  final pattern = RegExp("isAr\\s*\\?\\s*['\"](.*?)['\"]\\s*:\\s*['\"](.*?)['\"]");
  var match = pattern.firstMatch(text);
  if (match != null) {
    print("Matched!");
    print("1: ${match.group(1)}");
    print("2: ${match.group(2)}");
  } else {
    print("Failed to match.");
  }
}
