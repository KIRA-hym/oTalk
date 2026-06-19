import 'package:cloud_firestore/cloud_firestore.dart';

class Attendance {
  final String id;
  final String meetingId;
  final String? memberId; // null if guest
  final String? guestName; // null if regular member
  final bool isPaid;
  final DateTime timestamp;

  Attendance({
    required this.id,
    required this.meetingId,
    this.memberId,
    this.guestName,
    this.isPaid = false,
    required this.timestamp,
  });

  factory Attendance.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Attendance(
      id: doc.id,
      meetingId: data['meetingId'] ?? '',
      memberId: data['memberId'],
      guestName: data['guestName'],
      isPaid: data['isPaid'] ?? false,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meetingId': meetingId,
      'memberId': memberId,
      'guestName': guestName,
      'isPaid': isPaid,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
