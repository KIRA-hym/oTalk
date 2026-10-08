import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../repositories/member_repository.dart';
import 'member_form_dialog.dart';

class MemberSelectionDialog extends StatefulWidget {
  final List<String> alreadySelectedIds;
  final bool isAdmin;

  const MemberSelectionDialog({
    super.key, 
    required this.alreadySelectedIds, 
    this.isAdmin = true,
  });

  @override
  State<MemberSelectionDialog> createState() => _MemberSelectionDialogState();
}

class _MemberSelectionDialogState extends State<MemberSelectionDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final memberRepo = Provider.of<MemberRepository>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('참석자 선택', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // 검색바
            TextField(
              decoration: InputDecoration(
                hintText: '닉네임 초성/검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
            const SizedBox(height: 16),
            
            // 멤버 리스트
            Expanded(
              child: StreamBuilder<List<Member>>(
                stream: memberRepo.streamAllMembers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allMembers = snapshot.data ?? [];
                  // 이미 선택된 사람은 제외
                  final availableMembers = allMembers.where((m) => !widget.alreadySelectedIds.contains(m.id)).toList();
                  // 검색어 필터링
                  final filtered = availableMembers.where((m) => m.nickname.toLowerCase().contains(_searchQuery)).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('검색 결과가 없습니다.', textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          if (widget.isAdmin)
                            ElevatedButton(
                              onPressed: () async {
                                final newMember = await showDialog<Member>(
                                  context: context,
                                  builder: (ctx) => const MemberFormDialog(),
                                );
                                if (newMember != null && mounted) {
                                  Navigator.pop(context, newMember);
                                }
                              },
                              child: const Text('신규 멤버 등록하기'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final m = filtered[index];
                      return ListTile(
                        title: Text(m.fullDisplayText),
                        trailing: const Icon(Icons.add_circle_outline, color: Colors.amber),
                        onTap: () {
                          Navigator.pop(context, m); // 선택한 Member 전체 반환
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
