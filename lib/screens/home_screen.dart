import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repositories/auth_repository.dart';
import '../models/app_user.dart';
import 'admin_users_screen.dart';
import 'meeting_screen.dart';
import 'members_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final appUser = Provider.of<AppUser>(context);
    final isAdmin = appUser.role == 'admin' || appUser.role == 'super_admin';

    // 권한에 따른 탭 구성
    final List<Widget> pages = [];
    final List<BottomNavigationBarItem> navItems = [];

    if (isAdmin) {
      // 관리자 권한 (모든 탭)
      pages.addAll([
        const DashboardScreen(),
        const MeetingScreen(), // 2번째 탭에 모임 관리 화면 연결
        const MembersScreen(), // 3번째 탭 멤버 화면
        const AdminUsersScreen(), // 4번째 탭에 관리자 화면 연결
      ]);
      navItems.addAll([
        const BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: '대시보드'),
        const BottomNavigationBarItem(icon: Icon(Icons.event), label: '모임'),
        const BottomNavigationBarItem(icon: Icon(Icons.people), label: '멤버'),
        const BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
      ]);
    } else {
      // 일반 유저 권한 (모임 탭만)
      pages.addAll([
        const MeetingScreen(), // 1번째 탭에 모임 조회 및 관리
        const Center(child: Text('내 정보')),
      ]);
      navItems.addAll([
        const BottomNavigationBarItem(icon: Icon(Icons.event), label: '모임'),
        const BottomNavigationBarItem(icon: Icon(Icons.person), label: '내 정보'),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('서쪽방 모임'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Provider.of<AuthRepository>(context, listen: false).signOut();
            },
          )
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: navItems,
      ),
    );
  }
}
