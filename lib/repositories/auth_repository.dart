import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 사용자 스트림 (로그인 상태 변화 감지)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 현재 로그인된 유저 가져오기
  User? get currentUser => _auth.currentUser;

  // 구글 로그인 (웹 전용)
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final authProvider = GoogleAuthProvider();
      return await _auth.signInWithPopup(authProvider);
    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
