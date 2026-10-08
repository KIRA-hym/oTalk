import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'repositories/member_repository.dart';
import 'repositories/meeting_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/user_repository.dart';
import 'screens/login_screen.dart';
import 'screens/pending_screen.dart';
import 'models/app_user.dart';

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sync_data.dart';

Future<void> _runOneOffSync() async {
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
          'birthYear': '',
          'region': '',
          'gender': '',
          'joinDate': DateTime.now().toIso8601String(),
          'manualAttendance': manualAttendance,
        });
      }
    }
    print("===== SYNC SUCCESSFUL =====");
  } catch (e) {
    print("===== SYNC ERROR: \$e =====");
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // _runOneOffSync(); // 자동 동기화 주석 처리

  runApp(const OTalkApp());
}

class OTalkApp extends StatelessWidget {
  const OTalkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>(create: (_) => AuthRepository()),
        Provider<UserRepository>(create: (_) => UserRepository()),
        Provider<MemberRepository>(create: (_) => MemberRepository()),
        Provider<MeetingRepository>(create: (_) => MeetingRepository()),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: '서쪽방 모임',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            builder: (context, child) {
              final isDark = themeProvider.themeMode == ThemeMode.dark ||
                  (themeProvider.themeMode == ThemeMode.system &&
                      MediaQuery.of(context).platformBrightness == Brightness.dark);
              return Container(
                color: isDark ? const Color(0xFF000000) : const Color(0xFFE0E0E0),
                child: Center(
                  child: ClipRect(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 600),
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: const TextScaler.linear(1.0),
                        ),
                        child: child!,
                      ),
                    ),
                  ),
                ),
              );
            },
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'),
            ],
            home: const AuthWrapper(),
          );
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepo = Provider.of<AuthRepository>(context, listen: false);

    return StreamBuilder<User?>(
      stream: authRepo.authStateChanges,
      builder: (context, authSnapshot) {
        // Firebase 인증 로딩 중
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.amber)),
          );
        }

        final firebaseUser = authSnapshot.data;

        // 로그인된 유저가 없다면 로그인 화면 표시
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        // 로그인된 유저가 있다면 users 컬렉션 데이터 실시간 감지 (권한 및 상태)
        return Provider<AppUser?>(
          create: (_) => null, // Placeholder
          builder: (context, child) {
            final userRepo = Provider.of<UserRepository>(context, listen: false);
            return StreamBuilder<AppUser?>(
              stream: userRepo.streamUser(firebaseUser.uid),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: Colors.amber)),
                  );
                }

                final appUser = userSnapshot.data;

                // Firestore에 유저 문서가 없으면 (로그인 직후 딜레이 등)
                if (appUser == null) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator(color: Colors.amber)),
                  );
                }

                // Provider로 하위 위젯들에 AppUser 제공
                return Provider<AppUser>.value(
                  value: appUser,
                  child: _buildScreenByStatus(appUser),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildScreenByStatus(AppUser user) {
    if (user.status == 'pending') {
      return const PendingScreen();
    } else if (user.status == 'deleted') {
      // 강퇴 당한 유저
      return const Scaffold(
        body: Center(
          child: Text('접근 권한이 없습니다 (삭제된 계정).', style: TextStyle(color: Colors.red)),
        ),
      );
    } else {
      // active 상태 (user, admin, super_admin)
      return const HomeScreen();
    }
  }
}
