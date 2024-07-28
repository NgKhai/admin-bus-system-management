import 'dart:async';

import 'package:admin_bus_system_management/model/attendance_data.dart';
import 'package:admin_bus_system_management/model/bus_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import '../../../model/route_data.dart';
import '../../util/constant.dart';
import 'tracking_event.dart';
import 'tracking_state.dart';
import 'package:xml/xml.dart' as xml;

class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  final DatabaseReference _databaseReference;
  final CollectionReference _firestoreReference =
  FirebaseFirestore.instance.collection('Routes');
  final BusData busData;
  String? _currentRouteKey;
  DateTime? _startTime;
  String busTime = '';

  List<String> forwardTimeList = [];
  List<String> backwardTimeList = [];

  String? gpx;

  //

  List<LatLng> defaultRoute = [];
  List<Marker> markersDrop = [];
  final StreamController<double?> alignPositionStreamController =
  StreamController<double?>();
  AlignOnUpdate alignPositionOnUpdate = AlignOnUpdate.never;
  AlignOnUpdate alignDirectionOnUpdate = AlignOnUpdate.never;

  List<StudentDetail> studentDetailList = [];

  @override
  Future<void> close() {
    alignPositionStreamController.close();
    return super.close();
  }

  //

  TrackingBloc(this.busData)
      : _databaseReference =
  FirebaseDatabase.instance.ref().child(busData.busID),
        super(TrackingInitial()) {
    fetchData();

    on<StartTracking>(_onStartTracking);
    on<StopTracking>(_onStopTracking);
    on<UpdateTracking>(_onUpdateTracking);
    on<UpdateBusTime>(_onUpdateBusTime);
  }

  Future<void> fetchData() async {
    // Fetch GPX route and student details
    gpx = _getGpx();

    forwardTimeList = busData.busForwardTime;

    backwardTimeList = busData.busBackwardTime;

    busTime = forwardTimeList.first;

    defaultRoute = await parseGpx('assets/routes/$gpx.gpx');

    markersDrop.add(Marker(
      point: defaultRoute.first,
      child: const Icon(
        Icons.directions_bus,
        color: Constant.orangeHuflit,
        size: 40,
      ),
    ));
    markersDrop.add(Marker(
      point: defaultRoute.last,
      child: const Icon(
        CupertinoIcons.map_pin_ellipse,
        color: Constant.orangeHuflit,
        size: 40,
      ),
    ));

    emit(TrackingInitial(
      defaultRoute: defaultRoute,
      markersDrop: markersDrop,
      busTime: busTime,
    ));
  }

  Future<void> _onStartTracking(StartTracking event,
      Emitter<TrackingState> emit) async {
    // student
    studentDetailList = await _fetchStudentDetails();

    //  marker
    await _fetchMarkerDrop();

    // Check and remove existing route if any
    await _checkAndRemoveExistingRoute();

    emit(const TrackingInProgress(
      positions: [],
      speed: 0.0,
      duration: 0,
      distance: 0,
    ));

    final initialPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    _startTime = DateTime.now();

    final newRouteRef = _databaseReference.push();
    _currentRouteKey = newRouteRef.key;
    final initialRouteData = RoutesData(
      busID: busData.busID,
      studentDetail: studentDetailList,
      positions: [LatLng(initialPosition.latitude, initialPosition.longitude)],
      distance: 0,
      speed: 0.0,
      currentDate: getDate(_startTime!),
      busTime: busTime,
      startTime: getTime(_startTime!),
    );
    newRouteRef.set(initialRouteData.toMap());

    emit(TrackingInProgress(
      positions: [LatLng(initialPosition.latitude, initialPosition.longitude)],
      speed: 0.0,
      duration: 0,
      distance: 0,
    ));

    _trackLocation();
  }

  Future<void> _onStopTracking(StopTracking event,
      Emitter<TrackingState> emit) async {
    final currentState = state;

    if (currentState is TrackingInProgress) {
      String endTime = getTime(DateTime.now());

      if (_currentRouteKey != null) {
        final parentSnapshot = await _databaseReference.get();

        String uniqueKey = '';

        if (parentSnapshot.exists) {
          final dataMap = parentSnapshot.value as Map<dynamic, dynamic>;
          uniqueKey = dataMap.keys.first;

          final studentRef =
          _databaseReference.child(uniqueKey).child('StudentDetail');

          DatabaseEvent event = await studentRef.once();

          DataSnapshot childSnapshot = event.snapshot;

          if (childSnapshot.value != null) {
            List<dynamic> data = childSnapshot.value as List<dynamic>;
            List<StudentDetail> tempStudentDetailList = data.map((item) {
              return StudentDetail.fromRealtime(item as Map<dynamic, dynamic>);
            }).toList();

            for (var studentDetail in tempStudentDetailList) {
              studentDetail.dropTime ??= endTime;
            }

            studentDetailList = tempStudentDetailList;
          }
        }

        final routeData = RoutesData(
          busID: busData.busID,
          studentDetail: studentDetailList,
          positions: currentState.positions,
          distance: currentState.distance,
          speed: currentState.speed,
          currentDate: getDate(_startTime!),
          busTime: busTime,
          startTime: getTime(_startTime!),
          endTime: endTime,
        );

        // Save to Firestore
        await _firestoreReference.add(routeData.toMap());

        // Remove from real-time database--
        await _databaseReference.child(_currentRouteKey!).remove();
      }

      emit(TrackingStopped(
        positions: currentState.positions,
        speed: currentState.speed,
        duration: currentState.duration,
        distance: currentState.distance,
      ));
    }
  }

  void _onUpdateTracking(UpdateTracking event, Emitter<TrackingState> emit) {
    final currentState = state;
    if (currentState is TrackingInProgress) {
      final updatedPositions = List<LatLng>.from(currentState.positions)
        ..add(event.position);

      final totalDistance = _calculateTotalDistance(updatedPositions);
      final speedKmH = event.speed * 3.6;
      final durationInSeconds =
          DateTime
              .now()
              .difference(_startTime!)
              .inSeconds;

      if (_currentRouteKey != null) {
        final updatedRouteData = RoutesData(
          busID: busData.busID,
          // studentDetail: studentDetailList, // bỏ đi vì k cần update student
          positions: updatedPositions,
          distance: totalDistance,
          speed: speedKmH,
          currentDate: getDate(_startTime!),
          busTime: busTime,
          startTime: getTime(_startTime!),
        );
        _databaseReference
            .child(_currentRouteKey!)
            .update(updatedRouteData.toUpdate());
      }

      emit(TrackingInProgress(
        positions: updatedPositions,
        speed: speedKmH,
        duration: durationInSeconds / 60,
        distance: totalDistance,
      ));
    }
  }

  void _onUpdateBusTime(UpdateBusTime event, Emitter<TrackingState> emit) {
    busTime = event.busTime;
    emit(TrackingInitial(busTime: busTime));
  }

  Future<void> _trackLocation() async {
    while (state is TrackingInProgress) {
      final currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      add(UpdateTracking(
        position: LatLng(currentPosition.latitude, currentPosition.longitude),
        speed: currentPosition.speed,
        startTime: _startTime!,
      ));

      await Future.delayed(const Duration(seconds: 1));
    }
  }

  double _calculateTotalDistance(List<LatLng> positions) {
    double totalDistance = 0.0;
    for (int i = 0; i < positions.length - 1; i++) {
      totalDistance += Geolocator.distanceBetween(
        positions[i].latitude,
        positions[i].longitude,
        positions[i + 1].latitude,
        positions[i + 1].longitude,
      );
    }
    return totalDistance / 1000; // Convert meters to kilometers
  }

  Future<void> _checkAndRemoveExistingRoute() async {
    DataSnapshot snapshot = await _databaseReference.get();
    if (snapshot.exists) {
      await _databaseReference.remove();
    }
  }

  Future<List<StudentDetail>> _fetchStudentDetails() async {
    List<StudentDetail> tempstudentDetails = [];
    List<AttendanceData> attendanceListData = [];

    // Truy vấn thông qua bus id và bus time
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Attendances')
        .where('BusID', isEqualTo: busData.busID)
        .where('BusTime', isEqualTo: busTime)
        .get();

    attendanceListData = querySnapshot.docs
        .map((doc) => AttendanceData.fromFirestore(doc))
        .toList();

    for (var attendanceData in attendanceListData) {
      tempstudentDetails.add(StudentDetail(studentID: attendanceData.studentID,
          dropLatitude: attendanceData.dropLatitude,
          dropLongitude: attendanceData.dropLongitude));
    }

    return tempstudentDetails;
  }

  Future<void> _fetchMarkerDrop() async {
    for (final studentDetail in studentDetailList) {
      if (studentDetail.dropLatitude != defaultRoute.last.latitude &&
          studentDetail.dropLongitude != defaultRoute.last.longitude) {
        markersDrop.add(
          Marker(
            width: 100,
            height: 100,
            point: LatLng(studentDetail.dropLatitude.toDouble(),
                studentDetail.dropLongitude.toDouble()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Constant.orangeHuflit,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    studentDetail.studentID,
                    style: GoogleFonts.getFont(
                      'Montserrat',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.place,
                  color: Constant.orangeHuflit,
                  size: 40,
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  bool _checkIsMorning(TimeOfDay currentTime) {
    final currentMinutes = currentTime.hour * 60 + currentTime.minute;
    final isMorning =
        (6 * 60 <= currentMinutes) && (currentMinutes <= 11 * 60 + 45);

    return isMorning;
  }

  String _getGpx() {
    final currentTime = TimeOfDay.now();
    // final currentTime = TimeOfDay(hour: 12, minute: 45);
    final isMorning = _checkIsMorning(currentTime);

    final Map<String, String> forwardRoutes = {
      'BusLTR1': 'ltr-hm',
      'BusLTR2': 'ltr-hm',
      'BusPT1': 'pt-hm',
      'BusPT2': 'pt-hm',
      'BusGD1': 'gd-hm',
      'BusGD2': 'gd-hm',
      'BusVT1': 'vt-hm'
    };

    final Map<String, String> backwardRoutes = {
      'BusLTR1': 'hm-ltr',
      'BusLTR2': 'hm-ltr',
      'BusPT1': 'hm-pt',
      'BusPT2': 'hm-pt',
      'BusGD1': 'hm-gd',
      'BusGD2': 'hm-gd',
      'BusVT1': 'hm-vt'
    };

    return isMorning
        ? forwardRoutes[busData.busID] ?? ''
        : backwardRoutes[busData.busID] ?? '';
  }

  Future<List<LatLng>> parseGpx(String assetPath) async {
    final gpxString = await rootBundle.loadString(assetPath);
    final gpxXml = xml.XmlDocument.parse(gpxString);
    final coordinates = <LatLng>[];

    for (var element in gpxXml.findAllElements('trkpt')) {
      final lat = double.parse(element.getAttribute('lat')!);
      final lon = double.parse(element.getAttribute('lon')!);
      coordinates.add(LatLng(lat, lon));
    }

    return coordinates;
  }

  String getDate(DateTime selectedDate) {
    return DateFormat('dd/MM/yyyy').format(selectedDate);
  }

  String getTime(DateTime selectedDate) {
    return DateFormat('HH:mm:ss').format(selectedDate);
  }
}
