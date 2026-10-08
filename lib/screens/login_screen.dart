import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    final authRepo = Provider.of<AuthRepository>(context, listen: false);
    final userRepo = Provider.of<UserRepository>(context, listen: false);
    final userCredential = await authRepo.signInWithGoogle();

    // _authWrapper handles saveUserAfterLogin

    if (mounted) {
      setState(() {
        _isLoading = false;
      });

      if (userCredential == null) {
        // 로그인 실패 또는 취소
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그인에 실패했거나 취소되었습니다. (v1.0.1)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 앱 로고 또는 타이틀
              const Icon(
                Icons.forum_rounded,
                size: 80,
                color: Colors.amber, // Yellow accent
              ),
              const SizedBox(height: 24),
              const Text(
                '서쪽방 모임',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              const SizedBox(height: 60),
              
              // 구글 로그인 버튼
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.amber)
                  : SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.login, color: Colors.black),
                        label: const Text(
                          'Google 계정으로 시작하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber, // Yellow button
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _handleGoogleSignIn,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
