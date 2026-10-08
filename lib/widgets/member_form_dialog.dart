import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import '../repositories/member_repository.dart';
import 'package:provider/provider.dart';

class MemberFormDialog extends StatefulWidget {
  final Member? member; // null이면 신규 등록, 값이 있으면 수정

  const MemberFormDialog({super.key, this.member});

  @override
  State<MemberFormDialog> createState() => _MemberFormDialogState();
}

class _MemberFormDialogState extends State<MemberFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nicknameController;
  late TextEditingController _memoController;
  late String _gender;
  late DateTime _joinDate;
  bool _isLoading = false;

  bool get isEdit => widget.member != null;

  @override
  void initState() {
    super.initState();
    _nicknameController = TextEditingController(text: isEdit ? widget.member!.nickname : '');
    _memoController = TextEditingController(text: isEdit ? widget.member!.memo : '');
    _gender = (isEdit && (widget.member!.gender == '남' || widget.member!.gender == '여'))
        ? widget.member!.gender
        : '남';
    _joinDate = isEdit ? widget.member!.joinDate : DateTime.now();
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _saveMember() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final nickname = _nicknameController.text.trim();
    final memo = _memoController.text.trim();
    final repo = Provider.of<MemberRepository>(context, listen: false);

    try {
      if (isEdit) {
        final updatedMember = Member(
          id: widget.member!.id,
          nickname: nickname,
          gender: _gender,
          memo: memo,
          joinDate: _joinDate,
          manualAttendance: widget.member!.manualAttendance,
        );
        await repo.updateMember(updatedMember);
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context, updatedMember);
        }
      } else {
        final newMember = await repo.addMember(nickname, _gender, memo: memo);
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.pop(context, newMember); // return the new member
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEdit ? '멤버 정보 수정' : '신규 멤버 등록'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: '닉네임', hintText: '예: 홍길동'),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '닉네임을 입력해주세요.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _memoController,
                decoration: const InputDecoration(labelText: '메모 (선택)', hintText: '예: 직장동료'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Text('성별', style: TextStyle(color: Colors.grey)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment<String>(
                          value: '남',
                          label: Text('남'),
                        ),
                        ButtonSegment<String>(
                          value: '여',
                          label: Text('여'),
                        ),
                      ],
                      selected: {_gender},
                      onSelectionChanged: (Set<String> newSelection) {
                        setState(() {
                          _gender = newSelection.first;
                        });
                      },
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.amber;
                            }
                            return Colors.transparent;
                          },
                        ),
                        foregroundColor: WidgetStateProperty.resolveWith<Color>(
                          (Set<WidgetState> states) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.black;
                            }
                            return Colors.amber;
                          },
                        ),
                      ),
                    ),
                  ),
                ],
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
      ),
      actionsAlignment: isEdit ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
      actions: [
        if (isEdit)
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
                await Provider.of<MemberRepository>(context, listen: false).deleteMember(widget.member!.id);
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
                onPressed: _saveMember,
                child: Text(isEdit ? '저장' : '등록', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ],
    );
  }
}
