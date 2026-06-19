import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meeting.dart';
import '../models/app_user.dart';
import '../models/member.dart';
import '../repositories/meeting_repository.dart';
import '../repositories/member_repository.dart';
import '../widgets/member_selection_dialog.dart';

class MeetingFormSheet extends StatefulWidget {
  final Meeting? existingMeeting;

  const MeetingFormSheet({super.key, this.existingMeeting});

  @override
  State<MeetingFormSheet> createState() => _MeetingFormSheetState();
}

class _MeetingFormSheetState extends State<MeetingFormSheet> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  
  List<MeetingRound> _rounds = [];
  Map<String, String> _memberDisplayMap = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingMeeting != null) {
      _titleController.text = widget.existingMeeting!.title;
      _locationController.text = widget.existingMeeting!.location;
      _selectedDate = widget.existingMeeting!.date;
      _rounds = List.from(widget.existingMeeting!.rounds);
    } else {
      // 기본 1차 세팅
      _rounds.add(MeetingRound(roundName: '1차', totalCost: 0, attendees: [], location: '', bankAccount: ''));
      final now = DateTime.now();
      _selectedDate = DateTime(now.year, now.month, now.day, now.hour, (now.minute ~/ 10) * 10);
    }

    final memberRepo = Provider.of<MemberRepository>(context, listen: false);
    memberRepo.streamAllMembers().listen((members) {
      if (!mounted) return;
      setState(() {
        for (var m in members) {
          _memberDisplayMap[m.id] = m.fullDisplayText;
          // 하위 호환성을 위해 닉네임으로도 매핑해둠 (과거 데이터 호환)
          _memberDisplayMap[m.nickname] = m.fullDisplayText;
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
      if (_rounds.isNotEmpty) {
        copiedAttendees = List.from(_rounds.last.attendees); // 이전 차수 참석자 복사
      }
      _rounds.add(MeetingRound(roundName: newRoundName, totalCost: 0, attendees: copiedAttendees));
    });
  }

  void _updateRoundCost(int index, int cost) {
    setState(() {
      _rounds[index] = MeetingRound(
        roundName: _rounds[index].roundName,
        totalCost: cost,
        attendees: _rounds[index].attendees,
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

  Future<void> _saveMeeting() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('모임 제목을 입력해주세요.')));
      return;
    }

    setState(() => _isLoading = true);

    final appUser = Provider.of<AppUser>(context, listen: false);
    final repo = Provider.of<MeetingRepository>(context, listen: false);

    final meeting = Meeting(
      id: widget.existingMeeting?.id ?? FirebaseFirestore.instance.collection('meetings').doc().id,
      title: _titleController.text,
      date: _selectedDate,
      location: _locationController.text,
      creatorUid: widget.existingMeeting?.creatorUid ?? appUser.uid,
      rounds: _rounds,
      createdAt: widget.existingMeeting?.createdAt ?? DateTime.now(),
    );

    try {
      if (widget.existingMeeting == null) {
        await repo.addMeeting(meeting);
      } else {
        await repo.updateMeeting(widget.existingMeeting!, meeting);
      }

      if (mounted) {
        setState(() => _isLoading = false);
        Navigator.pop(context);
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
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.existingMeeting == null ? '새 모임 등록' : '모임 수정', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: '모임 제목', prefixIcon: Icon(Icons.title)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final pickedDate = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              // flutter_localizations가 적용되었으므로 기본적으로 한글 달력이 나옵니다.
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade800),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 20, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedDate.year}년 ${_selectedDate.month}월 ${_selectedDate.day}일',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: InkWell(
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
                                          data: const CupertinoThemeData(
                                            brightness: Brightness.dark,
                                          ),
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
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade800),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time, size: 20, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    decoration: const InputDecoration(labelText: '장소', prefixIcon: Icon(Icons.location_on)),
                  ),
                  const SizedBox(height: 24),
                  
                  const Text('참여 인원', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade800),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        ..._rounds[0].attendees.map((id) => Chip(
                          label: Text(_memberDisplayMap[id] ?? id),
                          onDeleted: () => _removeAttendeeFromRound(0, id),
                        )),
                        ActionChip(
                          avatar: const Icon(Icons.add, size: 16, color: Colors.black),
                          label: const Text('멤버 추가', style: TextStyle(color: Colors.black)),
                          backgroundColor: Colors.amber,
                          onPressed: () async {
                            final selectedMember = await showDialog<Member>(
                              context: context,
                              builder: (ctx) => MemberSelectionDialog(alreadySelectedIds: _rounds[0].attendees),
                            );
                            if (selectedMember != null) {
                              _addAttendeeToRound(0, selectedMember.id);
                            }
                          },
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 80), // 하단 여백
                ],
              ),
            ),
          ),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveMeeting,
              child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text('모임 저장하기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
            ),
          )
        ],
      ),
    );
  }
}
