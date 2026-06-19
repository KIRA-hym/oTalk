import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/meeting.dart';
import '../models/member.dart';
import '../models/app_user.dart';
import '../repositories/meeting_repository.dart';
import '../repositories/member_repository.dart';
import 'meeting_form_sheet.dart';
import 'meeting_detail_screen.dart';
import 'package:intl/intl.dart';

class MeetingScreen extends StatefulWidget {
  const MeetingScreen({super.key});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  
  late Stream<List<Meeting>> _meetingsStream;
  late Stream<List<Member>> _membersStream;

  @override
  void initState() {
    super.initState();
    final meetingRepo = Provider.of<MeetingRepository>(context, listen: false);
    final memberRepo = Provider.of<MemberRepository>(context, listen: false);
    _meetingsStream = meetingRepo.streamMeetings();
    _membersStream = memberRepo.streamAllMembers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meetingRepo = Provider.of<MeetingRepository>(context, listen: false);
    final appUser = Provider.of<AppUser>(context);

    return Scaffold(
      body: StreamBuilder<List<Member>>(
        stream: _membersStream,
        builder: (context, memberSnapshot) {
          final members = memberSnapshot.data ?? [];

          return StreamBuilder<List<Meeting>>(
            stream: _meetingsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              final meetings = snapshot.data ?? [];

              if (meetings.isEmpty && _searchQuery.isEmpty) {
                return const Center(child: Text('등록된 모임이 없습니다. 하단의 + 버튼을 눌러보세요!'));
              }

              // 검색 필터링 로직
              final filteredMeetings = meetings.where((meeting) {
                // 월별 필터
                if (meeting.date.year != _selectedMonth.year || meeting.date.month != _selectedMonth.month) {
                  return false;
                }

                if (_searchQuery.isEmpty) return true;
                
                final q = _searchQuery.toLowerCase();
                
                // 1. 모임 제목 매칭
                if (meeting.title.toLowerCase().contains(q)) return true;
                
                // 2. 날짜 상세 매칭 (일자 등)
                final dateStr = DateFormat('yyyy-MM-dd').format(meeting.date);
                if (dateStr.contains(q)) return true;
                
                // 3. 참여자 이름 매칭
                for (var attendeeIdOrName in meeting.uniqueAttendees) {
                  // ID로 멤버 찾기 시도
                  try {
                    final matchedMember = members.firstWhere((m) => m.id == attendeeIdOrName);
                    if (matchedMember.nickname.toLowerCase().contains(q) || matchedMember.displayName.toLowerCase().contains(q)) {
                      return true;
                    }
                  } catch (e) {
                    // 멤버 객체를 못 찾은 경우 (이름 텍스트 자체일 수 있음)
                    if (attendeeIdOrName.toLowerCase().contains(q)) {
                      return true;
                    }
                  }
                }
                
                return false;
              }).toList();

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, color: Colors.amber),
                                onPressed: () {
                                  setState(() {
                                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                                  });
                                },
                              ),
                              Text(
                                DateFormat('yyyy-MM').format(_selectedMonth),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, color: Colors.amber),
                                onPressed: () {
                                  setState(() {
                                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: '모임제목, 참여자 검색',
                              prefixIcon: const Icon(Icons.search, color: Colors.grey),
                              filled: true,
                              fillColor: Theme.of(context).cardColor,
                              contentPadding: const EdgeInsets.symmetric(vertical: 0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80, top: 0, left: 16, right: 16),
                      itemCount: filteredMeetings.length,
                      itemBuilder: (context, index) {
                        final meeting = filteredMeetings[index];
                        final isAdmin = appUser.role == 'admin' || appUser.role == 'super_admin';
                        final isCreator = meeting.creatorUid == appUser.uid;
                        final canEdit = isAdmin || isCreator;

                        final totalAttendeesCount = meeting.uniqueAttendees.length;

                        return Card(
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => Provider<AppUser>.value(
                                  value: appUser,
                                  child: MeetingDetailScreen(meeting: meeting),
                                )),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(meeting.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.amber)),
                                      ),
                                      if (canEdit)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                          onPressed: () => _confirmDelete(context, meetingRepo, meeting),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text('${DateFormat('yyyy-MM-dd HH:mm').format(meeting.date)} | ${meeting.location}', style: const TextStyle(color: Colors.grey)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Text('참여: $totalAttendeesCount명', style: const TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          );
        }
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final appUser = Provider.of<AppUser>(context, listen: false);
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            builder: (ctx) => Provider<AppUser>.value(
              value: appUser,
              child: const MeetingFormSheet(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('모임 등록', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MeetingRepository repo, Meeting meeting) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('모임 삭제', style: TextStyle(color: Colors.red)),
        content: const Text('이 모임을 삭제하시겠습니까?\n해당 모임의 참석 통계도 함께 취소됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소', style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              await repo.deleteMeeting(meeting);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
