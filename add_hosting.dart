import 'dart:io';
import 'dart:convert';

void main() {
  final file = File('C:/otalk_app/firebase.json');
  final String contents = file.readAsStringSync();
  final Map<String, dynamic> data = jsonDecode(contents);
  
  data['hosting'] = {
    "public": "build/web",
    "ignore": [
      "firebase.json",
      "**/.*",
      "**/node_modules/**"
    ],
    "rewrites": [
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  };
  
  file.writeAsStringSync(jsonEncode(data));
  print('Updated firebase.json');
}
