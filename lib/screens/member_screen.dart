import 'package:flutter/material.dart';
import '../core/constants.dart';

class MemberScreen extends StatelessWidget {
  const MemberScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('멤버 관리'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people, size: 80, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text('멤버 명부 화면입니다.', style: AppTextStyles.body1),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.person_add),
              label: const Text('새 멤버 등록'),
            ),
          ],
        ),
      ),
    );
  }
}
