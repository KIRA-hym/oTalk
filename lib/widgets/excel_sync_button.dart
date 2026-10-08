import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../sync_data.dart';

class ExcelSyncButton extends StatefulWidget {
  const ExcelSyncButton({Key? key}) : super(key: key);

  @override
  _ExcelSyncButtonState createState() => _ExcelSyncButtonState();
}

class _ExcelSyncButtonState extends State<ExcelSyncButton> {
  bool _isSyncing = false;

  Future<void> _syncExcelData() async {
    setState(() => _isSyncing = true);
    try {
      Map<String, dynamic> data = jsonDecode(excelSyncJson);
      final membersCol = FirebaseFirestore.instance.collection('members');
      final querySnapshot = await membersCol.get();
      
      Map<String, DocumentSnapshot> existingMembers = {};
      for (var doc in querySnapshot.docs) {
        existingMembers[doc['nickname']] = doc;
      }
      
      for (String nickname in data.keys) {
        Map<String, dynamic> monthlyData = data[nickname];
        Map<String, int> manualAttendance = {};
        monthlyData.forEach((k, v) {
          manualAttendance[k] = v as int;
        });
        
        if (existingMembers.containsKey(nickname)) {
          var doc = existingMembers[nickname]!;
          Map<String, dynamic> docData = (doc.data() as Map<String, dynamic>?) ?? {};
          Map<String, dynamic> currentManual = Map<String, dynamic>.from(docData['manualAttendance'] ?? {});
          manualAttendance.forEach((k, v) {
            currentManual[k] = v;
          });
          
          // Fix joinDate if it's accidentally a String from previous bug
          dynamic currentJoinDate = docData['joinDate'];
          if (currentJoinDate is String) {
            await doc.reference.update({
              'manualAttendance': currentManual,
              'joinDate': Timestamp.now(), // Fix the broken date
            });
          } else {
            await doc.reference.update({'manualAttendance': currentManual});
          }
        } else {
          var docRef = membersCol.doc();
          await docRef.set({
            'id': docRef.id,
            'nickname': nickname,
            'gender': '',
            'joinDate': Timestamp.now(), // Use proper Timestamp!
            'manualAttendance': manualAttendance,
          });
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('동기화 완료!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        print("SYNC ERROR: " + e.toString());
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: ' + e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: ElevatedButton.icon(
        onPressed: _isSyncing ? null : _syncExcelData,
        icon: _isSyncing 
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
          : const Icon(Icons.sync),
        label: Text(_isSyncing ? '데이터 동기화 중...' : '엑셀 데이터 Firebase에 일괄 강제 등록하기 (클릭!)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.redAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
        ),
      ),
    );
  }
}
