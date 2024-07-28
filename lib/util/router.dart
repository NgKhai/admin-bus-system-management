import 'package:admin_bus_system_management/bloc/tracking/tracking_provider.dart';
import 'package:admin_bus_system_management/model/bus_data.dart';
import 'package:admin_bus_system_management/model/map_history_router.dart';
import 'package:admin_bus_system_management/model/route_data.dart';
import 'package:admin_bus_system_management/screen/add_attendance_screen.dart';
import 'package:admin_bus_system_management/screen/face_recognition_screen.dart';
import 'package:admin_bus_system_management/screen/history_screen.dart';
import 'package:admin_bus_system_management/screen/map_history_screen.dart';
import 'package:admin_bus_system_management/screen/student_management_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../bloc/face_recognition/face_recognition_provider.dart';
import '../model/student_buslist_data.dart';
import '../screen/add_student_screen.dart';
import '../screen/home_screen.dart';
import '../screen/update_student_screen.dart';

final GoRouter router = GoRouter(
  routes: [
    // Admin
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
            path: 'student_management',
            builder: (context, state) {
              final busListData = state.extra as List<BusData>;
              return StudentManagementScreen(busListData: busListData);
            },
            routes: [
              GoRoute(
                  name: 'add_student',
                  path: 'add_student',
                  builder: (context, state) {
                    final busListData = state.extra as List<BusData>;
                    return AddStudentScreen(busListData: busListData);
                  }
              ),
              GoRoute(
                  name: 'update_student',
                  path: 'update_student',
                  builder: (context, state) {
                    final studentBusListData = state.extra as StudentBusListData;
                    return UpdateStudentScreen(studentBusListData: studentBusListData);
                  }
              ),
            ]
        ),
        GoRoute(
            path: 'face_recognition',
            builder: (context, state) {
              return const FaceRecognitionProvider();
              // return const FaceRecognitionScreen();
            },
            routes: [
              GoRoute(
                  name: 'add_attendance',
                  path: 'add_attendance',
                  builder: (context, state) {
                    final studentID = state.extra as String;
                    return AddAttendanceScreen(studentID: studentID);
                  }
              ),
            ]
        ),
        GoRoute(
            path: 'addTracking',
            builder: (context, state) {
              final busData = state.extra as BusData;
              return TrackingProvider(busData: busData);
            }
        ),
        GoRoute(
            path: 'history',
            builder: (context, state) {
              final busData = state.extra as BusData;
              return HistoryScreen(busData: busData);
            },
            routes: [
              GoRoute(
                  name: 'map_history',
                  path: 'map_history',
                  builder: (context, state) {
                    final mapData = state.extra as MapHistoryRouterData;
                    return MapHistoryScreen(mapData: mapData);
                  }
              ),
            ]
        ),
      ],
    ),

  ],
);
