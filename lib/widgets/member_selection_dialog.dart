import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/member.dart';
import '../models/app_user.dart';
import '../repositories/member_repository.dart';

class MemberSelectionDialog extends StatefulWidget {
  final List<String> alreadySelectedIds;
  final bool startWithAddingNew;

  const MemberSelectionDialog({super.key, required this.alreadySelectedIds, this.startWithAddingNew = false});

  @override
  State<MemberSelectionDialog> createState() => _MemberSelectionDialogState();
}

class _MemberSelectionDialogState extends State<MemberSelectionDialog> {
  String _searchQuery = '';
  late bool _isAddingNew;
  String _gender = '남';

  final _nicknameController = TextEditingController();
  final _birthYearController = TextEditingController();
  final _regionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isAddingNew = widget.startWithAddingNew;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthYearController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final memberRepo = Provider.of<MemberRepository>(context, listen: false);
    final appUser = Provider.of<AppUser>(context, listen: false);
    final isAdmin = appUser.role == 'super_admin' || appUser.role == 'admin';

    // 일반 사용자가 직접 신규 추가 모달로 열리려 하면 막기 위한 안전장치
    if (!isAdmin && _isAddingNew) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isAddingNew = false);
      });
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(_isAddingNew ? '신규 멤버 등록' : '참석자 선택', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            if (!_isAddingNew) ...[
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
                            if (isAdmin)
                              ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _nicknameController.text = _searchQuery;
                                    _isAddingNew = true;
                                  });
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
            ] else ...[
              // 신규 멤버 등록 폼
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(labelText: '닉네임'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _birthYearController,
                        decoration: const InputDecoration(labelText: '출생년도 (예: 90)'),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _regionController,
                        decoration: const InputDecoration(labelText: '지역 (예: 서울)'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: '성별'),
                        value: _gender,
                        items: const [
                          DropdownMenuItem(value: '남', child: Text('남')),
                          DropdownMenuItem(value: '여', child: Text('여')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _gender = val);
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                if (widget.startWithAddingNew) {
                                  Navigator.pop(context);
                                } else {
                                  setState(() => _isAddingNew = false);
                                }
                              },
                              child: const Text('취소', style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (_nicknameController.text.isEmpty || _birthYearController.text.isEmpty) return;
                                
                                // 신규 등록
                                final newMember = await memberRepo.addMember(
                                  _nicknameController.text,
                                  _birthYearController.text,
                                  _regionController.text,
                                  _gender,
                                );
                                
                                if (context.mounted) {
                                  Navigator.pop(context, newMember);
                                }
                              },
                              child: Text(widget.startWithAddingNew ? '등록' : '등록 및 선택'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
