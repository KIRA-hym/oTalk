import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String id;
  final String nickname;
  final String gender; // e.g., '남' 또는 '여'
  final DateTime joinDate;
  final Map<String, int> manualAttendance; // key: 'YYYY-MM', value: count

  Member({
    required this.id,
    required this.nickname,
    required this.gender,
    required this.joinDate,
    this.manualAttendance = const {},
  });

  factory Member.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Member(
      id: doc.id,
      nickname: data['nickname'] ?? '',
      gender: data['gender'] ?? '',
      joinDate: data['joinDate'] is Timestamp 
          ? (data['joinDate'] as Timestamp).toDate() 
          : (data['joinDate'] is String ? DateTime.parse(data['joinDate']) : DateTime.now()),
      manualAttendance: data['manualAttendance'] != null 
          ? Map<String, int>.from(data['manualAttendance'])
          : {},
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'nickname': nickname,
      'gender': gender,
      'joinDate': Timestamp.fromDate(joinDate),
      'manualAttendance': manualAttendance,
    };
  }

  // 검색 시 자동완성 등에서 보여줄 라벨 포맷
  String get displayName => '$nickname ($gender)';
  
  // 모임 등록/조회 시 칩에 보여줄 한 줄 표기 포맷
  String get fullDisplayText => '$nickname $gender'.trim();
}
