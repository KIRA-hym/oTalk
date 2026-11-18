import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../models/meeting.dart';
import '../widgets/quick_member_selection_dialog.dart';

class QuickSettlementScreen extends StatefulWidget {
  const QuickSettlementScreen({super.key});

  @override
  State<QuickSettlementScreen> createState() => _QuickSettlementScreenState();
}

class _QuickSettlementScreenState extends State<QuickSettlementScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _attendeeInputController = TextEditingController();
  final FocusNode _attendeeInputFocusNode = FocusNode();

  final List<MeetingRound> _rounds = [];
  final List<TextEditingController> _costControllers = [];
  final List<TextEditingController> _roundLocationControllers = [];
  final List<TextEditingController> _bankControllers = [];

  @override
  void initState() {
    super.initState();
    _initFirstRound();
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
    _titleController.dispose();
    _locationController.dispose();
    _attendeeInputController.dispose();
    _attendeeInputFocusNode.dispose();
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

  Set<String> get _currentUniqueAttendees {
    final attendees = <String>{};
    for (final round in _rounds) {
      attendees.addAll(round.attendees);
    }
    return attendees;
  }

  void _addTypedAttendeesToRound(int roundIndex, String rawInput) {
    final names = rawInput
        .split(RegExp(r'[,\s]+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (names.isEmpty) return;

    setState(() {
      if (_rounds.isEmpty) {
        _initFirstRound();
      }
      final currentAttendees = List<String>.from(_rounds[roundIndex].attendees);
      for (final name in names) {
        if (!currentAttendees.contains(name)) {
          currentAttendees.add(name);
        }
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

  void _handleTopAttendeeSubmit() {
    final text = _attendeeInputController.text.trim();
    if (text.isEmpty) return;
    _addTypedAttendeesToRound(0, text);
    _attendeeInputController.clear();
    _attendeeInputFocusNode.requestFocus();
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
      _attendeeInputController.clear();
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
        final costPerPersonStr =
            NumberFormat('#,###').format(round.costPerPerson);
        buffer.writeln(
          '금액 : $costStr / ${round.attendees.length} = $costPerPersonStr',
        );
      }
      buffer.writeln('맴버 : ${round.attendees.join(', ')}');

      if (!isSameAccount &&
          round.totalCost > 0 &&
          round.bankAccount.trim().isNotEmpty) {
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
        for (var name in round.attendees) {
          memberTotalCost[name] = (memberTotalCost[name] ?? 0) + costPerPerson;
        }
      }

      final Map<int, List<String>> costGroups = {};
      memberTotalCost.forEach((name, cost) {
        if (cost == 0) return;
        if (!costGroups.containsKey(cost)) {
          costGroups[cost] = [];
        }
        costGroups[cost]!.add(name);
      });

      final sortedCosts = costGroups.keys.toList()
        ..sort((a, b) => b.compareTo(a));
      if (sortedCosts.isNotEmpty) {
        for (var cost in sortedCosts) {
          final nicknames = costGroups[cost]!;
          buffer.writeln(nicknames.join(', '));
          buffer.writeln(' - ${NumberFormat('#,###').format(cost)}');
        }
        buffer.writeln();
      }

      if (firstAccount != null &&
          firstAccount.isNotEmpty &&
          sortedCosts.isNotEmpty) {
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _attendeeInputController,
                        focusNode: _attendeeInputFocusNode,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: '참석자 입력 후 엔터 (띄어쓰기·쉼표로 여러 명 가능)',
                          isDense: true,
                          filled: true,
                          fillColor: const Color(0xFF141414),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade800),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey.shade800),
                          ),
                        ),
                        onSubmitted: (_) => _handleTopAttendeeSubmit(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _handleTopAttendeeSubmit,
                      icon: const Icon(Icons.add, size: 16, color: Colors.black),
                      label: const Text(
                        '추가',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        minimumSize: const Size(0, 38),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_currentUniqueAttendees.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: _currentUniqueAttendees
                        .map(
                          (name) => Chip(
                            label: Text(
                              name,
                              style: const TextStyle(fontSize: 12),
                            ),
                            visualDensity: VisualDensity.compact,
                            onDeleted: () => _removeAttendeeFromAllRounds(name),
                          ),
                        )
                        .toList(),
                  ),
                ],
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                        icon: const Icon(
                                          Icons.copy,
                                          size: 16,
                                          color: Colors.amber,
                                        ),
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
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                  size: 20,
                                ),
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
                            onChanged: (val) =>
                                _updateRoundLocation(index, val),
                          ),
                          const SizedBox(height: 8),
                        ],
                        TextField(
                          controller: _costControllers[index],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: '결제 금액 (원)',
                            prefixText: '₩ ',
                          ),
                          onChanged: (val) =>
                              _updateRoundCost(index, int.tryParse(val) ?? 0),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _bankControllers[index],
                          decoration: const InputDecoration(
                            labelText: '입금 계좌',
                            hintText: '예: 홍길동 국민은행 123-456-7890',
                            prefixIcon: Icon(Icons.account_balance, size: 20),
                          ),
                          onChanged: (val) =>
                              _updateRoundBankAccount(index, val),
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
                                (name) => Chip(
                                  label: Text(name),
                                  onDeleted: () =>
                                      _removeAttendeeFromRound(index, name),
                                ),
                              ),
                              ActionChip(
                                avatar: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.black,
                                ),
                                label: const Text(
                                  '추가',
                                  style: TextStyle(color: Colors.black),
                                ),
                                backgroundColor: Colors.amber,
                                onPressed: () async {
                                  final typedName = await showDialog<String>(
                                    context: context,
                                    builder: (ctx) => QuickMemberSelectionDialog(
                                      existingPoolNames:
                                          _currentUniqueAttendees.toList(),
                                      alreadySelectedNames: round.attendees,
                                    ),
                                  );
                                  if (typedName != null &&
                                      typedName.trim().isNotEmpty) {
                                    _addTypedAttendeesToRound(index, typedName);
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
