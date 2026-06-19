import 'dart:io';
import 'dart:convert';
import 'package:excel/excel.dart';

void main() {
  final file = r'C:\Users\HYM\Documents\카카오톡 받은 파일\벙참 시트.xlsx';
  var bytes = File(file).readAsBytesSync();
  var excel = Excel.decodeBytes(bytes);

  var sheet = excel.tables['방인원 벙 참여'];
  if (sheet == null) return;

  List<String> rawNicknames = sheet.rows[1].skip(2).map((e) => e?.value?.toString().trim() ?? '').toList();

  Map<int, Map<String, int>> columnData = {};
  for (int i = 0; i < rawNicknames.length; i++) {
    columnData[i + 2] = {};
  }

  for (int i = 16; i < sheet.rows.length; i++) {
    var row = sheet.rows[i];
    var dateVal = row[1]?.value;
    if (dateVal == null) continue;
    
    String dateStr = dateVal.toString();
    if (dateStr.length < 7) continue;
    String monthKey = dateStr.substring(0, 7);

    for (int j = 2; j < row.length; j++) {
      if (j - 2 >= rawNicknames.length) break;
      var val = row[j]?.value;
      if (val != null && val.toString().trim() == '0') {
        columnData[j] ??= {};
        columnData[j]![monthKey] = (columnData[j]![monthKey] ?? 0) + 1;
      }
    }
  }

  Map<String, Map<String, int>> finalData = {};
  Map<String, int> nicknameTotalAttendance = {};

  for (int i = 0; i < rawNicknames.length; i++) {
    String nickname = rawNicknames[i];
    if (nickname.isEmpty) continue;
    
    int colIndex = i + 2;
    var monthlyData = columnData[colIndex] ?? {};
    int totalAttendance = monthlyData.values.fold(0, (sum, val) => sum + val);

    if (finalData.containsKey(nickname)) {
      int existingTotal = nicknameTotalAttendance[nickname] ?? 0;
      if (totalAttendance > existingTotal) {
        finalData[nickname] = monthlyData;
        nicknameTotalAttendance[nickname] = totalAttendance;
      }
    } else {
      finalData[nickname] = monthlyData;
      nicknameTotalAttendance[nickname] = totalAttendance;
    }
  }

  String jsonStr = jsonEncode(finalData);
  String dartCode = "const String excelSyncJson = r'''\n" + jsonStr + "\n''';\n";
  File('lib/sync_data.dart').writeAsStringSync(dartCode, encoding: utf8);
  print('Generated lib/sync_data.dart successfully');
}
