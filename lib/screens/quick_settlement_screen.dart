import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/meeting.dart';
import '../models/member.dart';
import '../repositories/member_repository.dart';
import '../widgets/quick_member_selection_dialog.dart';

class QuickSettlementScreen extends StatefulWidget {
  const QuickSettlementScreen({super.key});

  @override
  State<QuickSettlementScreen> createState() => _QuickSettlementScreenState();
}

class _QuickSettlementScreenState extends State<QuickSettlementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final List<MeetingRound> _rounds = [];
  final List<TextEditingController> _costControllers = [];
  final List<TextEditingController> _roundLocationControllers = [];
  final List<TextEditingController> _bankControllers = [];

  final Map<String, Member> _membersById = {};
  final Map<String, String> _memberDisplayMap = {};
  final Map<String, String> _memberNicknameMap = {};

  StreamSubscription<List<Member>>? _memberSub;

  @override
  void initState() {
    super.initState();
    _initFirstRound();
    _listenFirestoreMembers();
  }

  void _listenFirestoreMembers() {
    try {
      final memberRepo = Provider.of<MemberRepository>(context, listen: false);
      _memberSub = memberRepo.streamAllMembers().listen(
        (members) {
          if (!mounted) return;
          setState(() {
            // Keep any custom temporary members added in this session
            final customMembers = _membersById.values
                .where((m) => m.id.startsWith('temp_'))
                .toList();

            _membersById.clear();
            _memberDisplayMap.clear();
            _memberNicknameMap.clear();

            for (final m in members) {
              _membersById[m.id] = m;
              _memberDisplayMap[m.id] = m.fullDisplayText;
              _memberDisplayMap[m.nickname] = m.fullDisplayText;
              _memberNicknameMap[m.id] = m.nickname;
              _memberNicknameMap[m.nickname] = m.nickname;
            }
            for (final cm in customMembers) {
              _membersById[cm.id] = cm;
              _memberDisplayMap[cm.id] = cm.fullDisplayText;
              _memberNicknameMap[cm.id] = cm.nickname;
            }
          });
        },
      );
    } catch (_) {}
  }

  void _initFirstRound() {
    _rounds.clear();
    for (final c in _costControllers) {
      c.dispose();
    }
    for (final c in _roundLocationControllers) {
      c.dispose();
    }
    for (final c in _bankControllers) {
      c.dispose();
    }
    _costControllers.clear();
    _roundLocationControllers.clear();
    _bankControllers.clear();

    _rounds.add(
      MeetingRound(
        roundName: '1차',
        totalCost: 0,
        attendees: [],
        location: '',
        bankAccount: '',
      ),
    );
    _costControllers.add(TextEditingController());
    _roundLocationControllers.add(TextEditingController());
    _bankControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _memberSub?.cancel();
    _titleController.dispose();
    _locationController.dispose();
    for (final c in _costControllers) {
      c.dispose();
    }
    for (final c in _roundLocationControllers) {
      c.dispose();
    }
    for (final c in _bankControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<Member> get _customMembersList {
    final list = _membersById.values
        .where((m) => m.id.startsWith('temp_'))
        .toList();
    list.sort((a, b) => a.nickname.compareTo(b.nickname));
    return list;
  }

  void _registerMemberSelection(Member member) {
    _membersById[member.id] = member;
    _memberDisplayMap[member.id] = member.fullDisplayText;
    _memberNicknameMap[member.id] = member.nickname;
  }

  Set<String> get _currentUniqueAttendees {
    final attendees = <String>{};
    for (final round in _rounds) {
      attendees.addAll(round.attendees);
    }
    return attendees;
  }

  void _registerCustomMember(Member newMember) {
    setState(() {
      _membersById[newMember.id] = newMember;
      _memberDisplayMap[newMember.id] = newMember.fullDisplayText;
      _memberNicknameMap[newMember.id] = newMember.nickname;
    });
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
      _rounds.add(
        MeetingRound(
          roundName: newRoundName,
          totalCost: 0,
          attendees: copiedAttendees,
          location: '',
          bankAccount: initialBankAccount,
        ),
      );
      _costControllers.add(TextEditingController());
      _roundLocationControllers.add(TextEditingController());
      _bankControllers.add(TextEditingController(text: initialBankAccount));
    });
  }

  void _removeRound(int index) {
    setState(() {
      _rounds.removeAt(index);
      _costControllers.removeAt(index).dispose();
      _roundLocationControllers.removeAt(index).dispose();
      _bankControllers.removeAt(index).dispose();

      for (int i = 0; i < _rounds.length; i++) {
        _rounds[i] = MeetingRound(
          roundName: '${i + 1}차',
          totalCost: _rounds[i].totalCost,
          attendees: _rounds[i].attendees,
          location: _rounds[i].location,
          bankAccount: _rounds[i].bankAccount,
        );
      }
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

  void _resetAll() {
    setState(() {
      _titleController.clear();
      _locationController.clear();
      _initFirstRound();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('정산 입력 내용이 초기화되었습니다.')),
    );
  }

  String _generateShareText() {
    final titleText = _titleController.text.trim().isNotEmpty
        ? _titleController.text.trim()
        : '오늘의 모임';
    final buffer = StringBuffer();
    buffer.writeln('★ "$titleText" 정산내역 ★');
    buffer.writeln();

    bool isSameAccount = true;
    String? firstAccount;
    for (var r in _rounds) {
      if (r.bankAccount.trim().isNotEmpty) {
        if (firstAccount == null) {
          firstAccount = r.bankAccount.trim();
        } else if (firstAccount != r.bankAccount.trim()) {
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
        locationStr = _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : '장소미지정';
      } else {
        locationStr = round.location.trim().isNotEmpty
            ? round.location.trim()
            : '장소미지정';
      }

      buffer.writeln('$roundTitle 장소 : $locationStr');
      if (round.totalCost > 0) {
        final costStr = NumberFormat('#,###').format(round.totalCost);
        final costPerPersonStr = NumberFormat('#,###').format(round.costPerPerson);
        buffer.writeln('금액 : $costStr / ${round.attendees.length} = $costPerPersonStr');
      }
      final memberNicknames = round.attendees
          .map((id) => _memberNicknameMap[id] ?? id)
          .toList();
      buffer.writeln('맴버 : ${memberNicknames.join(', ')}');

      if (!isSameAccount && round.totalCost > 0 && round.bankAccount.trim().isNotEmpty) {
        buffer.writeln('[입금계좌]');
        buffer.writeln(round.bankAccount.trim());
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

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generateShareText()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('정산 내역이 클립보드에 복사되었습니다.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasAnyCost = _rounds.any((r) => r.totalCost > 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('간편 정산'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: '초기화',
            onPressed: _resetAll,
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: '정산내역 복사',
            onPressed: _copyToClipboard,
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
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    hintText: '모임 제목 (선택, 예: 오늘의 모임)',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 4),
                          border: InputBorder.none,
                          hintText: '1차 모임 장소 (선택)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '모임 인원 (${_currentUniqueAttendees.length}명)',
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ..._currentUniqueAttendees.map(
                      (id) => Chip(
                        label: Text(
                          _memberDisplayMap[id] ?? id,
                          style: const TextStyle(fontSize: 12),
                        ),
                        visualDensity: VisualDensity.compact,
                        onDeleted: () => _removeAttendeeFromAllRounds(id),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          if (_rounds.isEmpty) _addRound();
                          final selectedMember = await showDialog<Member>(
                            context: context,
                            builder: (ctx) => QuickMemberSelectionDialog(
                              customMembers: _customMembersList,
                              alreadySelectedIds: _currentUniqueAttendees.toList(),
                              onCustomMemberCreated: _registerCustomMember,
                            ),
                          );
                          if (selectedMember != null) {
                            _registerMemberSelection(selectedMember);
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
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _addRound,
                          icon: const Icon(Icons.add),
                          label: Text('${_rounds.length + 1}차 정산 추가'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                        ),
                        if (hasAnyCost || _currentUniqueAttendees.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Card(
                            margin: EdgeInsets.zero,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        '정산 내역 미리보기',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Colors.amber,
                                        ),
                                      ),
                                      TextButton.icon(
                                        onPressed: _copyToClipboard,
                                        icon: const Icon(Icons.copy, size: 16, color: Colors.amber),
                                        label: const Text(
                                          '복사',
                                          style: TextStyle(color: Colors.amber),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 16),
                                  SelectableText(
                                    _generateShareText(),
                                    style: const TextStyle(
                                      fontSize: 13,
                                      height: 1.5,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
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
                              _rounds.length == 1
                                  ? '총 정산금액'
                                  : '${round.roundName} 금액',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.amber,
                              ),
                            ),
                            if (index > 0)
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                onPressed: () => _removeRound(index),
                              ),
                          ],
                        ),
                        if (index > 0) ...[
                          TextField(
                            controller: _roundLocationControllers[index],
                            decoration: const InputDecoration(
                              labelText: '장소',
                              prefixIcon: Icon(Icons.location_on, size: 20),
                            ),
                            onChanged: (val) => _updateRoundLocation(index, val),
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextField(
                          controller: _costControllers[index],
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(
                            labelText: '결제 금액 (원)',
                            prefixText: '₩ ',
                          ),
                          onChanged: (val) => _updateRoundCost(index, int.tryParse(val) ?? 0),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bankControllers[index],
                          decoration: const InputDecoration(
                            labelText: '입금 계좌',
                            hintText: '예: 홍길동 국민은행 123-456-7890',
                            prefixIcon: Icon(Icons.account_balance, size: 20),
                          ),
                          onChanged: (val) => _updateRoundBankAccount(index, val),
                        ),
                        if (_rounds.length > 1) ...[
                          const SizedBox(height: 12),
                          const Text(
                            '참여 인원',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              ...round.attendees.map(
                                (id) => Chip(
                                  label: Text(_memberDisplayMap[id] ?? id),
                                  onDeleted: () => _removeAttendeeFromRound(index, id),
                                ),
                              ),
                              ActionChip(
                                avatar: const Icon(Icons.add, size: 16, color: Colors.black),
                                label: const Text(
                                  '추가',
                                  style: TextStyle(color: Colors.black),
                                ),
                                backgroundColor: Colors.amber,
                                onPressed: () async {
                                  final selectedMember = await showDialog<Member>(
                                    context: context,
                                    builder: (ctx) => QuickMemberSelectionDialog(
                                      customMembers: _customMembersList,
                                      alreadySelectedIds: round.attendees,
                                      onCustomMemberCreated: _registerCustomMember,
                                    ),
                                  );
                                  if (selectedMember != null) {
                                    _registerMemberSelection(selectedMember);
                                    _addAttendeeToRound(index, selectedMember.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                        if (round.totalCost > 0) ...[
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                '인당: ₩ ${NumberFormat('#,###').format(round.costPerPerson)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _copyToClipboard,
                  icon: const Icon(Icons.copy, color: Colors.black),
                  label: const Text(
                    '정산내역 복사하기',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Share.share(_generateShareText());
                  },
                  icon: const Icon(Icons.share, color: Colors.amber),
                  label: const Text(
                    '공유',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: Colors.amber),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
