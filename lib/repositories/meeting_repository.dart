import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting.dart';

class MeetingRepository {
  final CollectionReference _meetingsCollection = FirebaseFirestore.instance.collection('meetings');
  final CollectionReference _statsCollection = FirebaseFirestore.instance.collection('attendance_stats');

  // 모임 등록
  Future<void> addMeeting(Meeting meeting) async {
    await _meetingsCollection.doc(meeting.id).set(meeting.toFirestore());
    await _updateAttendanceStats(meeting.uniqueAttendees, isAdd: true);
  }

  // 모임 수정
  Future<void> updateMeeting(Meeting oldMeeting, Meeting newMeeting) async {
    // 1. 이전 출석 기록 빼기
    await _updateAttendanceStats(oldMeeting.uniqueAttendees, isAdd: false);
    
    // 2. 새로운 모임 정보 덮어쓰기
    await _meetingsCollection.doc(newMeeting.id).update(newMeeting.toFirestore());

    // 3. 새로운 출석 기록 더하기
    await _updateAttendanceStats(newMeeting.uniqueAttendees, isAdd: true);
  }

  // 모임 삭제 (Soft Delete)
  Future<void> deleteMeeting(Meeting meeting) async {
    // 참석 기록 빼기
    await _updateAttendanceStats(meeting.uniqueAttendees, isAdd: false);
    // 모임 삭제 (상태값을 deleted로 변경)
    await _meetingsCollection.doc(meeting.id).update({'status': 'deleted'});
  }

  // 전체 모임 가져오기 (최신순 정렬, 삭제된 모임 제외)
  Stream<List<Meeting>> streamMeetings() {
    return _meetingsCollection.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => Meeting.fromFirestore(doc))
          .where((m) => m.status == 'active')
          .toList();
    });
  }

  // ==== 내부 출석 통계 계산 로직 ====
  Future<void> _updateAttendanceStats(List<String> attendees, {required bool isAdd}) async {
    for (String nickname in attendees) {
      final statRef = _statsCollection.doc(nickname);
      
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(statRef);
        
        if (!snapshot.exists) {
          if (isAdd) {
            transaction.set(statRef, {'count': 1, 'nickname': nickname});
          }
        } else {
          final data = snapshot.data() as Map<String, dynamic>?;
          int currentCount = data?['count'] ?? 0;
          int newCount = isAdd ? currentCount + 1 : currentCount - 1;
          if (newCount < 0) newCount = 0;
          transaction.update(statRef, {'count': newCount});
        }
      });
    }
  }
}
