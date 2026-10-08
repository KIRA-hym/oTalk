import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/meeting.dart';
import '../models/app_user.dart';
import '../models/member.dart';
import '../repositories/meeting_repository.dart';
import '../repositories/member_repository.dart';
import '../widgets/member_selection_dialog.dart';

class MeetingDetailScreen extends StatefulWidget {
  final Meeting meeting;

  const MeetingDetailScreen({super.key, required this.meeting});

  @override
  State<MeetingDetailScreen> createState() => _MeetingDetailScreenState();
}

class _MeetingDetailScreenState extends State<MeetingDetailScreen> {
  late TextEditingController _titleController;
  late TextEditingController _locationController;
  late DateTime _selectedDate;
  
  late List<MeetingRound> _rounds;
  final Map<String, String> _memberDisplayMap = {};
  final Map<String, String> _memberNicknameMap = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.meeting.title);
    _locationController = TextEditingController(text: widget.meeting.location);
    _selectedDate = widget.meeting.date;
    _rounds = List.from(widget.meeting.rounds);

    final memberRepo = Provider.of<MemberRepository>(context, listen: false);
    memberRepo.streamAllMembers().listen((members) {
      if (!mounted) return;
      setState(() {
        for (var m in members) {
          _memberDisplayMap[m.id] = m.fullDisplayText;
          // 하위 호환성을 위해 닉네임으로도 매핑해둠
          _memberDisplayMap[m.nickname] = m.fullDisplayText;
          _memberNicknameMap[m.id] = m.nickname;
          _memberNicknameMap[m.nickname] = m.nickname;
        }
      });
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _addRound() {
    setState(() {
      final newRoundName = '${_rounds.length + 1}차';
      List<String> copiedAttendees = [];
      String initialBankAccount = '';
      if (_rounds.isNotEmpty) {
        copiedAttendees = List.from(_rounds.last.attendees);
        initialBankAccount = _rounds.first.bankAccount;
      }
      _rounds.add(MeetingRound(roundName: newRoundName, totalCost: 0, attendees: copiedAttendees, location: '', bankAccount: initialBankAccount));
    });
  }

  void _updateRoundCost(int index, int cost) {
    setState(() {
      _rounds[index] = MeetingRound(
        roundName: _rounds[index].roundName,
        totalCost: cost,
        attendees: _rounds[index].attendees,
        location: _rounds[index].location,
        bankAccount: _rounds[index].bankAccount,
      );
    });
  }

  void _updateRoundLocation(int index, String location) {
    setState(() {
      _rounds[index] = MeetingRound(
        roundName: _rounds[index].roundName,
        totalCost: _rounds[index].totalCost,
        attendees: _rounds[index].attendees,
        location: location,
        bankAccount: _rounds[index].bankAccount,
      );
    });
  }

  void _updateRoundBankAccount(int index, String bankAccount) {
    setState(() {
      _rounds[index] = MeetingRound(
        roundName: _rounds[index].roundName,
        totalCost: _rounds[index].totalCost,
        attendees: _rounds[index].attendees,
        location: _rounds[index].location,
        bankAccount: bankAccount,
      );
    });
  }

  void _addAttendeeToRound(int roundIndex, String id) {
    setState(() {
      final currentAttendees = List<String>.from(_rounds[roundIndex].attendees);
      if (!currentAttendees.contains(id)) {
        currentAttendees.add(id);
      }
      _rounds[roundIndex] = MeetingRound(
        roundName: _rounds[roundIndex].roundName,
        totalCost: _rounds[roundIndex].totalCost,
        attendees: currentAttendees,
        location: _rounds[roundIndex].location,
        bankAccount: _rounds[roundIndex].bankAccount,
      );
    });
  }

  void _removeAttendeeFromRound(int roundIndex, String id) {
    setState(() {
      final currentAttendees = List<String>.from(_rounds[roundIndex].attendees);
      currentAttendees.remove(id);
      _rounds[roundIndex] = MeetingRound(
        roundName: _rounds[roundIndex].roundName,
        totalCost: _rounds[roundIndex].totalCost,
        attendees: currentAttendees,
        location: _rounds[roundIndex].location,
        bankAccount: _rounds[roundIndex].bankAccount,
      );
    });
  }

  void _removeAttendeeFromAllRounds(String id) {
    setState(() {
      for (int i = 0; i < _rounds.length; i++) {
        final attendees = List<String>.from(_rounds[i].attendees);
        attendees.remove(id);
        _rounds[i] = MeetingRound(
          roundName: _rounds[i].roundName,
          totalCost: _rounds[i].totalCost,
          attendees: attendees,
          location: _rounds[i].location,
          bankAccount: _rounds[i].bankAccount,
        );
      }
    });
  }

  Set<String> get _currentUniqueAttendees {
    final attendees = <String>{};
    for (var round in _rounds) {
      attendees.addAll(round.attendees);
    }
    return attendees;
  }

  Future<void> _saveMeeting() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('모임 제목을 입력해주세요.')));
      return;
    }

    setState(() => _isSaving = true);
    final repo = Provider.of<MeetingRepository>(context, listen: false);
    
    final updatedMeeting = Meeting(
      id: widget.meeting.id,
      title: _titleController.text,
      date: _selectedDate,
      location: _locationController.text,
      creatorUid: widget.meeting.creatorUid,
      createdAt: widget.meeting.createdAt,
      rounds: _rounds,
    );
    
    await repo.updateMeeting(widget.meeting, updatedMeeting);
    
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('모임 정보와 정산 내역이 저장되었습니다.')));
    }
  }

  String _generateShareText() {
    final buffer = StringBuffer();
    buffer.writeln('★ "${_titleController.text}" 정산내역 ★');
    buffer.writeln();

    bool isSameAccount = true;
    String? firstAccount;
    for (var r in _rounds) {
      if (r.bankAccount.isNotEmpty) {
        if (firstAccount == null) {
          firstAccount = r.bankAccount;
        } else if (firstAccount != r.bankAccount) {
          isSameAccount = false;
          break;
        }
      }
    }

    for (int i = 0; i < _rounds.length; i++) {
      final round = _rounds[i];
      if (round.totalCost == 0 && round.attendees.isEmpty) continue;
      
      final roundTitle = _rounds.length == 1 ? '1차' : round.roundName;
      String locationStr;
      if (i == 0) {
        locationStr = _locationController.text.isNotEmpty ? _locationController.text : '장소미지정';
      } else {
        locationStr = round.location.isNotEmpty ? round.location : '장소미지정';
      }
      
      buffer.writeln('$roundTitle 장소 : $locationStr');
      if (round.totalCost > 0) {
        final costStr = NumberFormat('#,###').format(round.totalCost);
        final costPerPersonStr = NumberFormat('#,###').format(round.costPerPerson);
        buffer.writeln('금액 : $costStr / ${round.attendees.length} = $costPerPersonStr');
      }
      final memberNicknames = round.attendees.map((id) => _memberNicknameMap[id] ?? id).toList();
      buffer.writeln('맴버 : ${memberNicknames.join(', ')}');
      
      if (!isSameAccount && round.totalCost > 0 && round.bankAccount.isNotEmpty) {
        buffer.writeln('[입금계좌]');
        buffer.writeln(round.bankAccount);
      }
      buffer.writeln();
    }

    if (isSameAccount) {
      final Map<String, int> memberTotalCost = {};
      for (var round in _rounds) {
        if (round.attendees.isEmpty) continue;
        final costPerPerson = round.costPerPerson;
        for (var id in round.attendees) {
          memberTotalCost[id] = (memberTotalCost[id] ?? 0) + costPerPerson;
        }
      }

      final Map<int, List<String>> costGroups = {};
      memberTotalCost.forEach((id, cost) {
        if (cost == 0) return;
        if (!costGroups.containsKey(cost)) {
          costGroups[cost] = [];
        }
        costGroups[cost]!.add(_memberNicknameMap[id] ?? id);
      });

      final sortedCosts = costGroups.keys.toList()..sort((a, b) => b.compareTo(a));
      if (sortedCosts.isNotEmpty) {
        for (var cost in sortedCosts) {
          final nicknames = costGroups[cost]!;
          buffer.writeln(nicknames.join(', '));
          buffer.writeln(' - ${NumberFormat('#,###').format(cost)}');
        }
        buffer.writeln();
      }

      if (firstAccount != null && firstAccount.isNotEmpty && sortedCosts.isNotEmpty) {
        buffer.writeln('[입금계좌]');
        buffer.writeln(firstAccount);
        buffer.writeln();
      }
    }

    return buffer.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    final appUser = Provider.of<AppUser>(context);
    final isAdmin = appUser.role == 'admin' || appUser.role == 'super_admin';
    final isCreator = widget.meeting.creatorUid == appUser.uid;
    final canEdit = isAdmin || isCreator;

    return Scaffold(
      appBar: AppBar(
        title: const Text('상세정보'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '정산내역 복사',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _generateShareText()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('정산 내역이 클립보드에 복사되었습니다.')));
            },
          ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: '정산내역 공유',
            onPressed: () {
              Share.share(_generateShareText());
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade900,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canEdit) ...[
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                      hintText: '모임 제목',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _selectedDate = DateTime(
                                pickedDate.year,
                                pickedDate.month,
                                pickedDate.day,
                                _selectedDate.hour,
                                _selectedDate.minute,
                              );
                            });
                          }
                        },
                        child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate), style: const TextStyle(color: Colors.amber)),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: const Color(0xFF1E1E1E),
                            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
                            builder: (BuildContext builder) {
                              DateTime tempDate = _selectedDate;
                              return SizedBox(
                                height: 300,
                                child: Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context),
                                            child: const Text('취소', style: TextStyle(color: Colors.grey, fontSize: 16)),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              setState(() => _selectedDate = tempDate);
                                              Navigator.pop(context);
                                            },
                                            child: const Text('완료', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: CupertinoTheme(
                                        data: const CupertinoThemeData(brightness: Brightness.dark),
                                        child: CupertinoDatePicker(
                                          mode: CupertinoDatePickerMode.time,
                                          minuteInterval: 10,
                                          use24hFormat: false,
                                          initialDateTime: _selectedDate,
                                          onDateTimeChanged: (DateTime newDateTime) {
                                            tempDate = DateTime(
                                              _selectedDate.year,
                                              _selectedDate.month,
                                              _selectedDate.day,
                                              newDateTime.hour,
                                              newDateTime.minute,
                                            );
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        child: Text(DateFormat('HH:mm').format(_selectedDate), style: const TextStyle(color: Colors.amber)),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextField(
                          controller: _locationController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 4),
                            border: InputBorder.none,
                            hintText: '모임 장소',
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Text(widget.meeting.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.amber)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(DateFormat('yyyy-MM-dd').format(widget.meeting.date), style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(DateFormat('HH:mm').format(widget.meeting.date), style: const TextStyle(color: Colors.grey)),
                      const SizedBox(width: 16),
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(widget.meeting.location, style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                const Text('모임 인원', style: TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ..._currentUniqueAttendees.map((id) => Chip(
                      label: Text(_memberDisplayMap[id] ?? id, style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      onDeleted: canEdit ? () => _removeAttendeeFromAllRounds(id) : null,
                    )),
                    if (canEdit)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (_rounds.isEmpty) _addRound();
                            final selectedMember = await showDialog<Member>(
                              context: context,
                              builder: (ctx) => MemberSelectionDialog(
                                alreadySelectedIds: _currentUniqueAttendees.toList(),
                                isAdmin: isAdmin,
                              ),
                            );
                            if (selectedMember != null) {
                              _addAttendeeToRound(0, selectedMember.id);
                            }
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('추가', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 32),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _rounds.length + 1,
              itemBuilder: (context, index) {
                if (index == _rounds.length) {
                  if (!canEdit) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 16, bottom: 80),
                    child: OutlinedButton.icon(
                      onPressed: _addRound,
                      icon: const Icon(Icons.add),
                      label: const Text('추가'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
                    ),
                  );
                }

                final round = _rounds[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              (round.totalCost > 0 || canEdit)
                                  ? (_rounds.length == 1 ? '총 정산금액' : '${round.roundName} 금액')
                                  : (_rounds.length == 1 ? '참석자 명단' : '${round.roundName} 참석자'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.amber),
                            ),
                            if (index > 0 && canEdit)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => setState(() => _rounds.removeAt(index)),
                              )
                          ],
                        ),
                        if (canEdit) ...[
                          if (index > 0) ...[
                            TextField(
                              decoration: const InputDecoration(labelText: '장소', prefixIcon: Icon(Icons.location_on, size: 20)),
                              controller: TextEditingController(text: round.location)
                                ..selection = TextSelection.collapsed(offset: round.location.length),
                              onChanged: (val) => _updateRoundLocation(index, val),
                            ),
                            const SizedBox(height: 8),
                          ],
                          TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: '결제 금액 (원)', prefixText: '₩ '),
                            controller: TextEditingController(text: round.totalCost == 0 ? '' : round.totalCost.toString())
                              ..selection = TextSelection.collapsed(offset: round.totalCost == 0 ? 0 : round.totalCost.toString().length),
                            onChanged: (val) => _updateRoundCost(index, int.tryParse(val) ?? 0),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            decoration: const InputDecoration(
                              labelText: '입금 계좌',
                              hintText: '예: 홍길동 국민은행 123-456-7890',
                              prefixIcon: Icon(Icons.account_balance, size: 20),
                            ),
                            controller: TextEditingController(text: round.bankAccount)
                              ..selection = TextSelection.collapsed(offset: round.bankAccount.length),
                            onChanged: (val) => _updateRoundBankAccount(index, val),
                          ),
                        ] else ...[
                          if (index > 0 && round.location.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(round.location, style: const TextStyle(fontSize: 16)),
                                ],
                              ),
                            ),
                          if (round.totalCost > 0)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text('결제 금액: ₩ ${NumberFormat('#,###').format(round.totalCost)}', style: const TextStyle(fontSize: 16)),
                            ),
                          if (round.totalCost > 0 && round.bankAccount.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.account_balance, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text('입금 계좌: ${round.bankAccount}', style: const TextStyle(fontSize: 14, color: Colors.amberAccent))),
                                ],
                              ),
                            ),
                        ],
                        if (_rounds.length > 1) ...[
                          const SizedBox(height: 12),
                          const Text('참여 인원', style: TextStyle(fontSize: 14, color: Colors.grey)),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...round.attendees.map((id) => Chip(
                                label: Text(_memberDisplayMap[id] ?? id),
                                onDeleted: canEdit ? () => _removeAttendeeFromRound(index, id) : null,
                              )),
                              if (canEdit)
                                ActionChip(
                                  avatar: const Icon(Icons.add, size: 16, color: Colors.black),
                                  label: const Text('추가', style: TextStyle(color: Colors.black)),
                                  backgroundColor: Colors.amber,
                                  onPressed: () async {
                                    final selectedMember = await showDialog<Member>(
                                      context: context,
                                      builder: (ctx) => MemberSelectionDialog(
                                        alreadySelectedIds: round.attendees,
                                        isAdmin: isAdmin,
                                      ),
                                    );
                                    if (selectedMember != null) {
                                      _addAttendeeToRound(index, selectedMember.id);
                                    }
                                  },
                                )
                            ],
                          ),
                        ],
                        if (round.totalCost > 0) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('인당: ₩ ${NumberFormat('#,###').format(round.costPerPerson)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          )
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: canEdit
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveMeeting,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Colors.amber,
                  ),
                  child: _isSaving 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : const Text('저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                ),
              ),
            )
          : null,
    );
  }
}
