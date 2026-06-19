import 'dart:io';
import 'package:excel/excel.dart';

void main() {
  final file = r'C:\Users\HYM\Documents\카카오톡 받은 파일\벙참 시트.xlsx';
  var bytes = File(file).readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);

  var sheet = excel.tables['방인원 벙 참여'];
  if (sheet == null) {
    print('Sheet not found!');
    return;
  }

  // Row 2 (index 1) has nicknames starting from index 2
  var nicknames = sheet.rows[1].skip(2).map((e) => e?.value?.toString().trim()).toList();
  print("Nicknames: ");
  print(nicknames);

  Set<String> uniqueValues = {};
  for (int i = 16; i < sheet.rows.length; i++) {
    var row = sheet.rows[i];
    for (int j = 2; j < row.length; j++) {
      var val = row[j]?.value;
      if (val != null) {
        uniqueValues.add(val.toString().trim());
      }
    }
  }
  print("Unique values in cells: ");
  print(uniqueValues);
}
