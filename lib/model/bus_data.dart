import 'package:cloud_firestore/cloud_firestore.dart';

class BusData {
  final String busID;
  final String busName;
  final String busLicense;
  final String busStartColor;
  final String busEndColor;
  final String busImage;
  final List<String> busForwardTime;
  final List<String> busBackwardTime;

  BusData(this.busID, this.busName, this.busLicense, this.busStartColor,
      this.busEndColor, this.busImage, this.busForwardTime, this.busBackwardTime);

  toJson() {
    return {
      "BusID": busID,
      "BusName": busName,
      "BusLicense": busLicense,
      "BusStartColor": busStartColor,
      "BusEndColor": busEndColor,
      "BusImage": busImage,
      "BusForwardTime": busForwardTime,
      "BusBackwardTime": busBackwardTime,
    };
  }

  factory BusData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    return BusData(
      data?['BusID'] ?? '',
      data?['BusName'] ?? '',
      data?['BusLicense'] ?? '',
      data?['BusStartColor'] ?? '',
      data?['BusEndColor'] ?? '',
      data?['BusImage'] ?? '',
      data?['BusForwardTime'] != null
          ? List<String>.from(data!['BusForwardTime'])
          : [],
      data?['BusBackwardTime'] != null
          ? List<String>.from(data!['BusBackwardTime'])
          : [],
    );
  }
}