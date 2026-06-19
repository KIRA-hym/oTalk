import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_user.dart';
import '../repositories/user_repository.dart';
import '../providers/theme_provider.dart';

class AdminUsersScreen extends StatelessWidget {
  const AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('설정'),
          bottom: const TabBar(
            tabs: [
              Tab(text: '승인대기'),
              Tab(text: '권한관리'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _PendingUsersTab(),
            _ActiveUsersTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('테마 설정', style: TextStyle(fontWeight: FontWeight.bold)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.light_mode, color: Colors.orange),
                      title: const Text('기본 (라이트 모드)'),
                      onTap: () {
                        Provider.of<ThemeProvider>(context, listen: false).toggleTheme(false);
                        Navigator.pop(ctx);
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.dark_mode, color: Colors.deepPurple),
                      title: const Text('다크 모드'),
                      onTap: () {
                        Provider.of<ThemeProvider>(context, listen: false).toggleTheme(true);
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
          icon: const Icon(Icons.palette),
          label: const Text('테마'),
        ),
      ),
    );
  }
}

class _PendingUsersTab extends StatelessWidget {
  const _PendingUsersTab();

  @override
  Widget build(BuildContext context) {
    final userRepo = Provider.of<UserRepository>(context, listen: false);

    return StreamBuilder<List<AppUser>>(
      stream: userRepo.streamPendingUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('대기 중인 가입자가 없습니다.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.amber,
                child: Icon(Icons.person, color: Colors.black),
              ),
              title: Text(user.displayName),
              subtitle: Text(user.email),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () {
                      _showApproveDialog(context, userRepo, user);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () {
                      _showRejectDialog(context, userRepo, user);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showApproveDialog(BuildContext context, UserRepository repo, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('가입 승인'),
        content: Text('${user.displayName} 님의 가입을 승인하시겠습니까?\n\n초기 권한은 일반 회원(user)으로 부여됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await repo.updateUserRoleAndStatus(user.uid, 'user', 'active');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('승인', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, UserRepository repo, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('가입 거절'),
        content: Text('${user.displayName} 님의 가입 요청을 거절하고 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await repo.deleteUser(user.uid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('거절 및 삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ActiveUsersTab extends StatelessWidget {
  const _ActiveUsersTab();

  @override
  Widget build(BuildContext context) {
    final userRepo = Provider.of<UserRepository>(context, listen: false);
    final currentUser = Provider.of<AppUser>(context);

    return StreamBuilder<List<AppUser>>(
      stream: userRepo.streamActiveUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.amber));
        }

        final users = snapshot.data ?? [];

        if (users.isEmpty) {
          return const Center(child: Text('기존 회원이 없습니다.'));
        }

        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isMe = user.uid == currentUser.uid;

            return ListTile(
              leading: CircleAvatar(
                backgroundColor: _getRoleColor(user.role),
                child: const Icon(Icons.person, color: Colors.black),
              ),
              title: Text('${user.displayName}${isMe ? ' (나)' : ''}'),
              subtitle: Text('${user.email}\n권한: ${_getRoleName(user.role)}'),
              isThreeLine: true,
              trailing: isMe ? null : _buildActionButtons(context, userRepo, currentUser, user),
            );
          },
        );
      },
    );
  }

  String _getRoleName(String role) {
    switch (role) {
      case 'super_admin': return '슈퍼 관리자 (마스터)';
      case 'admin': return '관리자';
      default: return '일반 회원';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin': return Colors.redAccent;
      case 'admin': return Colors.amber;
      default: return Colors.grey;
    }
  }

  Widget? _buildActionButtons(BuildContext context, UserRepository repo, AppUser currentUser, AppUser targetUser) {
    // 타겟이 슈퍼관리자인 경우 아무도 건드릴 수 없음
    if (targetUser.role == 'super_admin') {
      return null;
    }

    // 내가 일반관리자인데 타겟도 일반관리자면 건드릴 수 없음
    if (currentUser.role == 'admin' && targetUser.role == 'admin') {
      return null;
    }

    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (value == 'make_admin') {
          await repo.updateUserRoleAndStatus(targetUser.uid, 'admin', 'active');
        } else if (value == 'make_user') {
          await repo.updateUserRoleAndStatus(targetUser.uid, 'user', 'active');
        } else if (value == 'kick' && currentUser.role == 'super_admin') {
          _showKickDialog(context, repo, targetUser);
        } else if (value == 'transfer_master' && currentUser.role == 'super_admin') {
          _showTransferMasterDialog(context, repo, currentUser, targetUser);
        }
      },
      itemBuilder: (context) {
        final items = <PopupMenuEntry<String>>[];

        if (targetUser.role == 'user') {
          items.add(const PopupMenuItem(value: 'make_admin', child: Text('관리자로 승급')));
        } else if (targetUser.role == 'admin') {
          items.add(const PopupMenuItem(value: 'make_user', child: Text('일반회원으로 강등')));
        }

        if (currentUser.role == 'super_admin') {
          items.add(const PopupMenuItem(value: 'transfer_master', child: Text('슈퍼관리자 위임 (나는 관리자로 강등)')));
          items.add(const PopupMenuDivider());
          items.add(const PopupMenuItem(value: 'kick', child: Text('강퇴 및 삭제', style: TextStyle(color: Colors.red))));
        }

        return items;
      },
    );
  }

  void _showKickDialog(BuildContext context, UserRepository repo, AppUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('회원 강퇴', style: TextStyle(color: Colors.red)),
        content: Text('${user.displayName} 님을 강퇴하시겠습니까?\n이 작업은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              await repo.deleteUser(user.uid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('강퇴', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showTransferMasterDialog(BuildContext context, UserRepository repo, AppUser currentUser, AppUser targetUser) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('슈퍼관리자 권한 위임', style: TextStyle(color: Colors.red)),
        content: Text('${targetUser.displayName} 님에게 마스터 권한을 넘기시겠습니까?\n\n방장님은 관리자로 강등되며, 이 결정은 돌이킬 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              // 1. 타겟 유저를 super_admin으로
              await repo.updateUserRoleAndStatus(targetUser.uid, 'super_admin', 'active');
              // 2. 나는 admin으로
              await repo.updateUserRoleAndStatus(currentUser.uid, 'admin', 'active');
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('위임 확인', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
