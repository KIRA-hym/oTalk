import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/member.dart';
import '../models/meeting.dart';
import '../models/app_user.dart';
import '../repositories/member_repository.dart';
import '../repositories/meeting_repository.dart';
import 'meeting_detail_screen.dart';
import '../widgets/excel_sync_button.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final memberRepo = Provider.of<MemberRepository>(context, listen: false);
    final meetingRepo = Provider.of<MeetingRepository>(context, listen: false);
    final appUser = Provider.of<AppUser>(context);
    
    final currentMonthKey = DateFormat('yyyy-MM').format(DateTime.now());
    final todayDateString = DateFormat('yyyy년 M월 d일').format(DateTime.now());

    return Scaffold(
      
      body: StreamBuilder<List<Meeting>>(
        stream: meetingRepo.streamMeetings(),
        builder: (context, meetingSnapshot) {
          if (meetingSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }
          final meetings = meetingSnapshot.data ?? [];
          
          // 이번 달 모임 필터링
          final thisMonthMeetings = meetings.where((m) {
            return DateFormat('yyyy-MM').format(m.date) == currentMonthKey;
          }).toList();

          // 이번 달 모임 개수
          final totalMeetingsThisMonth = thisMonthMeetings.length;

          // 이번 달 총 모임 참여자 수 (중복 제거)
          final uniqueAttendeesThisMonth = <String>{};
          for (var m in thisMonthMeetings) {
            uniqueAttendeesThisMonth.addAll(m.uniqueAttendees);
          }
          final uniqueAttendeesCount = uniqueAttendeesThisMonth.length;

          // 최근 등록된 모임 3개 (최신순 정렬 후 앞 3개)
          final sortedMeetings = List<Meeting>.from(meetings)
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final recentMeetings = sortedMeetings.take(3).toList();

          return StreamBuilder<List<Member>>(
            stream: memberRepo.streamAllMembers(),
            builder: (context, memberSnapshot) {
              if (memberSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.amber));
              }

              final members = memberSnapshot.data ?? [];



              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    // 상단: 날짜 및 전체 누적 통계
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          todayDateString,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Text(
                              '누적 모임 ${meetings.length}회 | 총 ${members.length}명',
                              style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    

                    
                    // 중단: 좌우 분할 통계 (이달 총 모임, 이달 총 참여자)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.event_available, color: Colors.amberAccent, size: 24),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('이번 달 모임', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('$totalMeetingsThisMonth회', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, )),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).dividerColor),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.people_alt, color: Colors.amberAccent, size: 24),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text('참여자 수', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Text('$uniqueAttendeesCount명', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, )),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 하단: 최근 등록된 모임 (최대 3개)
                    const Text('최근 등록된 모임', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, )),
                    const SizedBox(height: 16),
                    if (recentMeetings.isEmpty)
                      const Center(child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text('최근 등록된 모임이 없습니다.', style: TextStyle(color: Colors.grey)),
                      ))
                    else
                      ...recentMeetings.map((meeting) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
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
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Theme.of(context).dividerColor),
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: Colors.amber.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.calendar_today, color: Colors.amberAccent, size: 20),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meeting.title, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${DateFormat('yyyy-MM-dd HH:mm').format(meeting.date)} | ${meeting.location}', 
                                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 32),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
