import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

class RoutesData {
  final String busID;
  final List<StudentDetail>? studentDetail;
  final List<LatLng> positions;
  final num distance; // Distance in kilometers
  final num speed; // Speed in meters/second
  final String currentDate;
  final String busTime;
  final String startTime;
  final String? endTime; // Nullable to handle ongoing tracking

  RoutesData({
    required this.busID,
    this.studentDetail,
    required this.positions,
    required this.distance,
    required this.speed,
    required this.currentDate,
    required this.busTime,
    required this.startTime,
    this.endTime,
  });

  // Method to convert RouteData to a map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'BusID': busID,
      'StudentDetail': studentDetail!.map((detail) => detail.toJson()).toList(),
      'Positions': positions
          .map((pos) => {'Latitude': pos.latitude, 'Longitude': pos.longitude})
          .toList(),
      'Distance': distance,
      'Speed': speed,
      'CurrentDate': currentDate,
      'BusTime': busTime,
      'StartTime': startTime,
      'EndTime': endTime,
    };
  }

  Map<String, dynamic> toUpdate() {
    return {
      'BusID': busID,
      'Positions': positions
          .map((pos) => {'Latitude': pos.latitude, 'Longitude': pos.longitude})
          .toList(),
      'Distance': distance,
      'Speed': speed,
      'CurrentDate': currentDate,
      'BusTime': busTime,
      'StartTime': startTime,
      'EndTime': endTime,
    };
  }

  // Factory method to create a RouteData from a map (e.g., from Firebase)
  factory RoutesData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    List<StudentDetail> foodDetailHistoryList = [];
    if (data?['StudentDetail'] != null) {
      var list = data?['StudentDetail'] as List;
      foodDetailHistoryList = list.map((item) => StudentDetail.fromFirestore(item)).toList();
    }

    return RoutesData(
      busID: data?['BusID'],
      studentDetail: (data?['StudentDetail'] as List)
          .map(
            (item) =>
                StudentDetail.fromFirestore(item)).toList(),
      positions: (data?['Positions'] as List)
          .map(
            (pos) =>
            LatLng(
              pos['Latitude'],
              pos['Longitude'],
            ),
      )
          .toList(),
      distance: data?['Distance'],
      speed: data?['Speed'],
      currentDate: data?['CurrentDate'],
      busTime: data?['BusTime'],
      startTime: data?['StartTime'],
      endTime: data?['EndTime'],
    );
  }
}

class StudentDetail {
  final String studentID;
  final num dropLatitude;
  final num dropLongitude;
  String? dropTime;

  StudentDetail(
      {required this.studentID, required this.dropLatitude, required this.dropLongitude, this.dropTime});

  toJson() {
    return {
      "StudentID": studentID,
      "DropLatitude": dropLatitude,
      "DropLongitude": dropLongitude,
      "DropTime": dropTime,
    };
  }

  factory StudentDetail.fromFirestore(Map<String, dynamic> data) {
    return StudentDetail(
      studentID: data['StudentID'],
      dropLatitude: data['DropLatitude'],
      dropLongitude: data['DropLongitude'],
      dropTime: data['DropTime'],
    );
  }

  factory StudentDetail.fromRealtime(Map<dynamic, dynamic> data) {
    return StudentDetail(
      studentID: data['StudentID'] ?? '',
      dropLatitude: data['DropLatitude'] ?? 0,
      dropLongitude: data['DropLongitude'] ?? 0,
      dropTime: data['DropTime'],
    );
  }
}
