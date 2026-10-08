import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/member.dart';

class MemberRepository {
  final CollectionReference _membersCollection = FirebaseFirestore.instance.collection('members');

  // 멤버 추가
  Future<Member> addMember(String nickname, String gender) async {
    final docRef = _membersCollection.doc();
    final newMember = Member(
      id: docRef.id,
      nickname: nickname,
      gender: gender,
      joinDate: DateTime.now(),
    );
    await docRef.set(newMember.toFirestore());
    return newMember;
  }

  // 전체 멤버 목록 가져오기 (이름순 정렬)
  Stream<List<Member>> streamAllMembers() {
    return _membersCollection.orderBy('nickname').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Member.fromFirestore(doc)).toList();
    });
  }

  // 멤버 정보 수정
  Future<void> updateMember(Member member) async {
    await _membersCollection.doc(member.id).update(member.toFirestore());
  }

  // 멤버 삭제
  Future<void> deleteMember(String id) async {
    await _membersCollection.doc(id).delete();
  }
}
