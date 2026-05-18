void main() {
  String text = "isAr ? 'Today's Crowd Forecast' : 'Today'";
  
  var p1 = RegExp("isAr\\s*\\?\\s*['\"](.*?)['\"]\\s*:\\s*['\"](.*?)['\"]");
  print("No backref: ${p1.hasMatch(text)}");
  
  var p2 = RegExp("isAr\\s*\\?\\s*(['\"])(.*?)\\1\\s*:\\s*(['\"])(.*?)\\3");
  print("Backref fixed: ${p2.hasMatch(text)}");
}
