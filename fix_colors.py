import os

def replace_exact(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old, new in replacements:
        content = content.replace(old, new)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

# dashboard_screen.dart
replace_exact('C:/otalk_app/lib/screens/dashboard_screen.dart', [
    ('backgroundColor: Colors.black,', ''),
    ('color: Colors.white,', ''),
    ('color: Colors.white', ''),
    ('color: Colors.black.withOpacity(0.8)', 'color: Theme.of(context).cardColor'),
    ('color: Colors.black54', 'color: Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5)'),
    ('Colors.grey.shade900', 'Theme.of(context).cardColor'),
    ('Colors.grey.shade800', 'Theme.of(context).dividerColor')
])

# meeting_screen.dart
replace_exact('C:/otalk_app/lib/screens/meeting_screen.dart', [
    ('Colors.grey.shade900', 'Theme.of(context).cardColor'),
    (', color: Colors.white', '')
])

# members_screen.dart
replace_exact('C:/otalk_app/lib/screens/members_screen.dart', [
    ('color: isSelected ? Colors.amber : Colors.white', 'color: isSelected ? Colors.amber : Theme.of(context).textTheme.bodyMedium?.color'),
    ('Colors.grey.shade900', 'Theme.of(context).cardColor')
])

print("Replacements done.")
