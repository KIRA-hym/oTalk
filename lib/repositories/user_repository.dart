import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class UserRepository {
  final CollectionReference _usersCollection = FirebaseFirestore.instance.collection('users');

  // 사용자 로그인 후 DB 저장 및 정보 반환
  Future<AppUser?> saveUserAfterLogin(User firebaseUser) async {
    final docRef = _usersCollection.doc(firebaseUser.uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      // 이미 가입된 유저
      return AppUser.fromFirestore(docSnapshot);
    } else {
      // 신규 가입자
      // users 컬렉션이 비어있는지 확인하여 첫 유저라면 super_admin 권한 부여
      final querySnapshot = await _usersCollection.limit(1).get();
      final isFirstUser = querySnapshot.docs.isEmpty;

      final role = isFirstUser ? 'super_admin' : 'user';
      final status = isFirstUser ? 'active' : 'pending';

      final newUser = AppUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? '',
        role: role,
        status: status,
        createdAt: DateTime.now(),
      );

      await docRef.set(newUser.toFirestore());
      return newUser;
    }
  }

  // UID로 사용자 정보 실시간 가져오기 (권한 감지용)
  Stream<AppUser?> streamUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    });
  }

  // 가입 대기자 목록 가져오기 (admin/super_admin 용)
  Stream<List<AppUser>> streamPendingUsers() {
    return _usersCollection
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return users;
        });
  }

  // 승인 완료된 전체 회원 목록 가져오기
  Stream<List<AppUser>> streamActiveUsers() {
    return _usersCollection
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
          final users = snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
          users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return users;
        });
  }

  // 사용자 상태/권한 업데이트 (승인/권한 변경)
  Future<void> updateUserRoleAndStatus(String uid, String role, String status) async {
    await _usersCollection.doc(uid).update({
      'role': role,
      'status': status,
    });
  }

  // 사용자 강제 탈퇴 (삭제)
  Future<void> deleteUser(String uid) async {
    // 논리적 삭제(deleted 상태로 변경) 또는 물리적 삭제 선택 가능. 여기서는 완전히 삭제.
    await _usersCollection.doc(uid).delete();
  }
}
