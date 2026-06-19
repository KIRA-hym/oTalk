import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import '../repositories/member_repository.dart';
import 'package:provider/provider.dart';

class MemberEditDialog extends StatefulWidget {
  final Member member;

  const MemberEditDialog({super.key, required this.member});

  @override
  State<MemberEditDialog> createState() => _MemberEditDialogState();
}

class _MemberEditDialogState extends State<MemberEditDialog> {
  late TextEditingController _nicknameController;
  late TextEditingController _birthYearController;
  late TextEditingController _regionController;
  late String _gender;
  late DateTime _joinDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: widget.member.nickname);
    _birthYearController = TextEditingController(text: widget.member.birthYear);
    _regionController = TextEditingController(text: widget.member.region);
    _gender = (widget.member.gender == '남' || widget.member.gender == '여') 
        ? widget.member.gender 
        : '남';
    _joinDate = widget.member.joinDate;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _birthYearController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _updateMember() async {
    final nickname = _nicknameController.text.trim();
    final birthYear = _birthYearController.text.trim();
    final region = _regionController.text.trim();

    if (nickname.isEmpty || birthYear.isEmpty || region.isEmpty) return;

    setState(() => _isLoading = true);

    final updatedMember = Member(
      id: widget.member.id,
      nickname: nickname,
      birthYear: birthYear,
      region: region,
      gender: _gender,
      joinDate: _joinDate,
      manualAttendance: widget.member.manualAttendance,
    );

    await Provider.of<MemberRepository>(context, listen: false)
        .updateMember(updatedMember);

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true); // true indicates update success
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('멤버 정보 수정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(labelText: '닉네임', hintText: '예: 홍길동'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _birthYearController,
              decoration: const InputDecoration(labelText: '생년 (2자리)', hintText: '예: 90'),
              keyboardType: TextInputType.number,
              maxLength: 2,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _regionController,
              decoration: const InputDecoration(labelText: '지역', hintText: '예: 서울'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _gender,
              decoration: const InputDecoration(labelText: '성별'),
              items: const [
                DropdownMenuItem(value: '남', child: Text('남')),
                DropdownMenuItem(value: '여', child: Text('여')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _gender = val);
              },
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _joinDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2030),
                );
                if (pickedDate != null) {
                  setState(() => _joinDate = pickedDate);
                }
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: '가입일'),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('yyyy년 MM월 dd일').format(_joinDate)),
                    const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: const Text('멤버 삭제', style: TextStyle(color: Colors.red)),
                content: const Text('정말로 이 멤버를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없으며, 연결된 수기 데이터도 삭제됩니다.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소', style: TextStyle(color: Colors.grey))),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, true), 
                    child: const Text('삭제', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                  ),
                ],
              ),
            );

            if (confirm == true) {
              setState(() => _isLoading = true);
              await Provider.of<MemberRepository>(context, listen: false).deleteMember(widget.member.id);
              if (mounted) {
                setState(() => _isLoading = false);
                Navigator.pop(context, true);
              }
            }
          },
          child: const Text('삭제', style: TextStyle(color: Colors.red)),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소', style: TextStyle(color: Colors.grey)),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.amber)),
              )
            else
              TextButton(
                onPressed: _updateMember,
                child: const Text('저장', style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ],
    );
  }
}
