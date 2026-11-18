import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../repositories/member_repository.dart';

class QuickMemberSelectionDialog extends StatefulWidget {
  final List<Member> customMembers;
  final List<String> alreadySelectedIds;
  final void Function(Member newCustomMember) onCustomMemberCreated;

  const QuickMemberSelectionDialog({
    super.key,
    required this.customMembers,
    required this.alreadySelectedIds,
    required this.onCustomMemberCreated,
  });

  @override
  State<QuickMemberSelectionDialog> createState() => _QuickMemberSelectionDialogState();
}

class _QuickMemberSelectionDialogState extends State<QuickMemberSelectionDialog> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _showNewMemberInlineDialog({String initialNickname = ''}) async {
    final nicknameCtrl = TextEditingController(text: initialNickname);
    final memoCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final created = await showDialog<Member>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('신규 인원 추가 (1회성)'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nicknameCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: '닉네임',
                  hintText: '예: 홍길동',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return '닉네임을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: memoCtrl,
                decoration: const InputDecoration(
                  labelText: '메모 (선택)',
                  hintText: '예: 친구, 게스트',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('취소', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final nickname = nicknameCtrl.text.trim();
              final memo = memoCtrl.text.trim();
              final customMember = Member(
                id: 'temp_${DateTime.now().microsecondsSinceEpoch}',
                nickname: nickname,
                gender: '',
                memo: memo,
                joinDate: DateTime.now(),
              );
              Navigator.pop(ctx, customMember);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('추가', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (created != null && mounted) {
      widget.onCustomMemberCreated(created);
      Navigator.pop(context, created);
    }
  }

  @override
  Widget build(BuildContext context) {
    final memberRepo = Provider.of<MemberRepository>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 520,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '참석자 선택',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showNewMemberInlineDialog(
                    initialNickname: _searchController.text.trim(),
                  ),
                  icon: const Icon(Icons.person_add, size: 18, color: Colors.amber),
                  label: const Text(
                    '신규 인원 추가',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '닉네임 검색 또는 신규 추가',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Member>>(
                stream: memberRepo.streamAllMembers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    );
                  }

                  final dbMembers = snapshot.data ?? [];
                  final mergedMembers = <Member>[
                    ...widget.customMembers,
                    ...dbMembers,
                  ];

                  final availableMembers = mergedMembers
                      .where((m) => !widget.alreadySelectedIds.contains(m.id))
                      .toList();

                  final filtered = availableMembers.where((m) {
                    if (_searchQuery.isEmpty) return true;
                    final q = _searchQuery.toLowerCase();
                    return m.nickname.toLowerCase().contains(q) ||
                        m.memo.toLowerCase().contains(q) ||
                        m.fullDisplayText.toLowerCase().contains(q);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _searchQuery.isEmpty
                                ? '선택 가능한 인원이 없습니다.'
                                : '\'$_searchQuery\' 검색 결과가 없습니다.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () => _showNewMemberInlineDialog(
                              initialNickname: _searchQuery,
                            ),
                            icon: const Icon(Icons.add, color: Colors.black),
                            label: Text(
                              _searchQuery.isEmpty
                                  ? '신규 인원 직접 추가하기'
                                  : '\'$_searchQuery\' 신규 인원으로 추가',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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
                          Navigator.pop(context, m);
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
