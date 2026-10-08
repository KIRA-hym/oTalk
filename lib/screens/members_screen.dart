import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../models/member.dart';
import '../models/app_user.dart';
import '../models/meeting.dart';
import '../repositories/member_repository.dart';
import '../repositories/meeting_repository.dart';
import '../widgets/member_form_dialog.dart';
import '../widgets/member_selection_dialog.dart';
import '../sync_data.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMemberId;
  
  late Stream<List<Meeting>> _meetingsStream;
  late Stream<List<Member>> _membersStream;

  @override
  void initState() {
    super.initState();
    final memberRepo = Provider.of<MemberRepository>(context, listen: false);
    final meetingRepo = Provider.of<MeetingRepository>(context, listen: false);
    _meetingsStream = meetingRepo.streamMeetings();
    _membersStream = memberRepo.streamAllMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isSyncing = false;

  Future<void> _syncExcelData() async {
    setState(() => _isSyncing = true);
    try {
      Map<String, dynamic> data = jsonDecode(excelSyncJson);
      final membersCol = FirebaseFirestore.instance.collection('members');
      final querySnapshot = await membersCol.get();
      
      Map<String, DocumentSnapshot> existingMembers = {};
      for (var doc in querySnapshot.docs) {
        existingMembers[doc['nickname']] = doc;
      }
      
      for (String nickname in data.keys) {
        Map<String, dynamic> monthlyData = data[nickname];
        Map<String, int> manualAttendance = {};
        monthlyData.forEach((k, v) {
          manualAttendance[k] = v as int;
        });
        
        if (existingMembers.containsKey(nickname)) {
          var doc = existingMembers[nickname]!;
          Map<String, dynamic> currentManual = Map<String, dynamic>.from(doc['manualAttendance'] ?? {});
          manualAttendance.forEach((k, v) {
            currentManual[k] = v;
          });
          await doc.reference.update({'manualAttendance': currentManual});
        } else {
          var docRef = membersCol.doc();
          await docRef.set({
            'id': docRef.id,
            'nickname': nickname,
            'gender': '',
            'joinDate': Timestamp.now(),
            'manualAttendance': manualAttendance,
          });
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('동기화 완료!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: \$e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _showManualAttendanceDialog(BuildContext context, Member member) {
    String selectedYear = DateTime.now().year.toString();
    String selectedMonth = DateTime.now().month.toString().padLeft(2, '0');
    final TextEditingController countController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: const Text('수기 기록 추가', style: TextStyle(color: Colors.amber)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedYear,
                          dropdownColor: Theme.of(context).cardColor,
                          items: List.generate(10, (index) => (DateTime.now().year - index).toString())
                              .map((y) => DropdownMenuItem(value: y, child: Text('$y년')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setStateDialog(() => selectedYear = val);
                          },
                          decoration: const InputDecoration(labelText: '년도'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: selectedMonth,
                          dropdownColor: Theme.of(context).cardColor,
                          items: List.generate(12, (index) => (index + 1).toString().padLeft(2, '0'))
                              .map((m) => DropdownMenuItem(value: m, child: Text('$m월')))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setStateDialog(() => selectedMonth = val);
                          },
                          decoration: const InputDecoration(labelText: '월'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: countController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: '참석 횟수',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('취소', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final count = int.tryParse(countController.text);
                    if (count == null || count <= 0) return;

                    final key = '$selectedYear-$selectedMonth';
                    final updatedManual = Map<String, int>.from(member.manualAttendance);
                    updatedManual[key] = (updatedManual[key] ?? 0) + count;

                    final updatedMember = Member(
                      id: member.id,
                      nickname: member.nickname,
                      gender: member.gender,
                      joinDate: member.joinDate,
                      manualAttendance: updatedManual,
                    );

                    await Provider.of<MemberRepository>(context, listen: false).updateMember(updatedMember);
                    if (context.mounted) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
                  child: const Text('저장', style: TextStyle(color: Colors.black)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<Meeting>>(
        stream: _meetingsStream,
        builder: (context, meetingSnapshot) {
          if (meetingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          final meetings = meetingSnapshot.data ?? [];

          return StreamBuilder<List<Member>>(
            stream: _membersStream,
            builder: (context, memberSnapshot) {
              try {
                if (memberSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.amber));
                }

                final allMembers = memberSnapshot.data ?? [];
                if (allMembers.isEmpty) {
                  return const Center(child: Text('등록된 멤버가 없습니다.'));
                }

                Map<String, int> memberCounts = {};
                for (var member in allMembers) {
                  int autoCount = meetings.where((m) => m.uniqueAttendees.contains(member.id) || m.uniqueAttendees.contains(member.nickname)).length;
                  int manualCount = member.manualAttendance.values.fold(0, (sum, val) => sum + val);
                  memberCounts[member.id] = autoCount + manualCount;
                }

                final filteredMembers = allMembers.where((m) {
                  return m.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();
                
                filteredMembers.sort((a, b) => memberCounts[b.id]!.compareTo(memberCounts[a.id]!));

                Member? selectedMember;
                if (_selectedMemberId != null) {
                  try {
                    selectedMember = allMembers.firstWhere((m) => m.id == _selectedMemberId);
                  } catch (e) {
                    selectedMember = null;
                  }
                }
                
                bool isTwoPane = selectedMember != null;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '멤버 검색 (이름, 년생, 지역 등)',
                          prefixIcon: const Icon(Icons.search, color: Colors.grey),
                          suffixIcon: _searchQuery.isNotEmpty 
                            ? IconButton(
                                icon: const Icon(Icons.clear, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                          filled: true,
                          fillColor: Theme.of(context).cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Pane: Member List
                          Expanded(
                            flex: 2,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: filteredMembers.length,
                              itemBuilder: (context, index) {
                                final member = filteredMembers[index];
                                final isSelected = member.id == _selectedMemberId;

                                return Card(
                                  color: isSelected ? Colors.amber.withOpacity(0.2) : null,
                                  shape: RoundedRectangleBorder(
                                    side: isSelected ? const BorderSide(color: Colors.amber, width: 2) : BorderSide.none,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (_selectedMemberId == member.id) {
                                          _selectedMemberId = null;
                                        } else {
                                          _selectedMemberId = member.id;
                                        }
                                      });
                                    },
                                    onLongPress: () {
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => MemberFormDialog(member: member),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              isTwoPane ? member.nickname : member.fullDisplayText,
                                              style: TextStyle(
                                                fontSize: 16, 
                                                fontWeight: FontWeight.bold,
                                                color: isSelected ? Colors.amber : Theme.of(context).textTheme.bodyMedium?.color
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Right Pane: Detail
                          if (selectedMember != null) ...[
                            const VerticalDivider(width: 1, color: Colors.grey),
                            Expanded(
                              flex: 3,
                              child: _buildDetailPane(selectedMember, meetings),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                );
              } catch (e, stackTrace) {
                return Center(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: \$e\n\$stackTrace', style: const TextStyle(color: Colors.red)),
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (!isAdmin) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('권한이 없습니다.')));
            return;
          }
          showDialog(
            context: context,
            builder: (ctx) => const MemberFormDialog(),
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('멤버 등록'),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
      ),
    );
  }

  Widget _buildDetailPane(Member member, List<Meeting> meetings) {
    // 1. Calculate automated attendance per month
    final Map<String, int> monthlyStats = {};
    for (var m in meetings) {
      if (m.uniqueAttendees.contains(member.id) || m.uniqueAttendees.contains(member.nickname)) {
        final key = DateFormat('yyyy-MM').format(m.date);
        monthlyStats[key] = (monthlyStats[key] ?? 0) + 1;
      }
    }

    // 2. Merge with manual attendance
    member.manualAttendance.forEach((key, val) {
      monthlyStats[key] = (monthlyStats[key] ?? 0) + val;
    });

    // 3. Sort by YYYY-MM descending
    final sortedKeys = monthlyStats.keys.toList()..sort((a, b) => b.compareTo(a));

    final totalCount = monthlyStats.values.fold(0, (sum, val) => sum + val);

    return Container(
      color: Theme.of(context).cardColor,
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '참석 내역',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.amber),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => MemberFormDialog(member: member),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.grey, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Text(
                      '총 $totalCount회',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('월별 참석 횟수', style: TextStyle(color: Colors.grey, fontSize: 14)),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _showManualAttendanceDialog(context, member),
                    icon: const Icon(Icons.add, size: 16, color: Colors.amberAccent),
                    label: const Text('참여추가', style: TextStyle(color: Colors.amberAccent)),
                  ),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.grey),
          Expanded(
            child: sortedKeys.isEmpty 
              ? const Center(child: Text('참석 내역이 없습니다.', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, index) {
                    final key = sortedKeys[index];
                    final count = monthlyStats[key]!;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      trailing: Text(
                        '$count회', 
                        style: const TextStyle(fontSize: 16, color: Colors.amberAccent, fontWeight: FontWeight.bold)
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
