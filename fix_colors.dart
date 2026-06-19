import 'dart:io';

void replaceExact(String filepath, List<List<String>> replacements) {
  final file = File(filepath);
  var content = file.readAsStringSync();
  
  for (final replacement in replacements) {
    content = content.replaceAll(replacement[0], replacement[1]);
  }
  
  file.writeAsStringSync(content);
}

void main() {
  replaceExact('C:/otalk_app/lib/screens/dashboard_screen.dart', [
    ['backgroundColor: Colors.black,', ''],
    ['color: Colors.white,', ''],
    ['color: Colors.white', ''],
    ['color: Colors.black.withOpacity(0.8)', 'color: Theme.of(context).cardColor'],
    ['color: Colors.black54', 'color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)'],
    ['Colors.grey.shade900', 'Theme.of(context).cardColor'],
    ['Colors.grey.shade800', 'Theme.of(context).dividerColor'],
  ]);

  replaceExact('C:/otalk_app/lib/screens/meeting_screen.dart', [
    ['Colors.grey.shade900', 'Theme.of(context).cardColor'],
    [', color: Colors.white', ''],
  ]);

  replaceExact('C:/otalk_app/lib/screens/members_screen.dart', [
    ['color: isSelected ? Colors.amber : Colors.white', 'color: isSelected ? Colors.amber : Theme.of(context).textTheme.bodyMedium?.color'],
    ['Colors.grey.shade900', 'Theme.of(context).cardColor'],
  ]);

  print('Replacements done.');
}
