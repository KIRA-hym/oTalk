import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingRound {
  final String roundName; // 예: "1차", "2차"
  final int totalCost;    // 해당 차수의 총 비용
  final List<String> attendees; // 해당 차수에 참석한 member의 id 또는 nickname 목록
  final String location;  // 해당 차수의 장소 (예: "스타벅스")
  final String bankAccount; // 해당 차수의 입금 계좌 (텍스트 형태)

  MeetingRound({
    required this.roundName,
    required this.totalCost,
    required this.attendees,
    this.location = '',
    this.bankAccount = '',
  });

  int get costPerPerson {
    if (attendees.isEmpty || totalCost == 0) return 0;
    return (totalCost / attendees.length).round();
  }

  factory MeetingRound.fromMap(Map<String, dynamic> map) {
    return MeetingRound(
      roundName: map['roundName'] ?? '',
      totalCost: map['totalCost']?.toInt() ?? 0,
      attendees: List<String>.from(map['attendees'] ?? []),
      location: map['location'] ?? '',
      bankAccount: map['bankAccount'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'roundName': roundName,
      'totalCost': totalCost,
      'attendees': attendees,
      'location': location,
      'bankAccount': bankAccount,
    };
  }
}

class Meeting {
  final String id;
  final String title;
  final DateTime date;
  final String location;
  final String creatorUid;
  final List<MeetingRound> rounds;
  final DateTime createdAt;
  final String status;

  Meeting({
    required this.id,
    required this.title,
    required this.date,
    required this.location,
    required this.creatorUid,
    required this.rounds,
    required this.createdAt,
    this.status = 'active',
  });

  // 해당 모임의 총비용
  int get totalMeetingCost => rounds.fold(0, (sum, round) => sum + round.totalCost);

  // 이 모임에 1번이라도 참석한 모든 사람(중복 제거) - 출석 통계용
  List<String> get uniqueAttendees {
    final Set<String> uniqueList = {};
    for (var round in rounds) {
      uniqueList.addAll(round.attendees);
    }
    return uniqueList.toList();
  }

  factory Meeting.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Meeting(
      id: doc.id,
      title: data['title'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      creatorUid: data['creatorUid'] ?? '',
      rounds: (data['rounds'] as List<dynamic>? ?? [])
          .map((r) => MeetingRound.fromMap(r as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      status: data['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'date': Timestamp.fromDate(date),
      'location': location,
      'creatorUid': creatorUid,
      'rounds': rounds.map((r) => r.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status,
    };
  }
}
