import 'package:cloud_firestore/cloud_firestore.dart';

class StudentData {
  final String studentID;
  final String studentName;
  final String dateHistory;
  final List<String> studentAssignBus;


  StudentData(this.studentID, this.studentName, this.dateHistory,
      this.studentAssignBus);

  toJson() {
    return {
      "StudentID": studentID,
      "StudentName": studentName,
      "DateHistory": dateHistory,
      "StudentAssignBus": studentAssignBus,
    };
  }

  factory StudentData.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

    return StudentData(
      data?['StudentID'] ?? '',
      data?['StudentName'] ?? '',
      data?['DateHistory'] ?? '',
      data?['StudentAssignBus'] != null
          ? List<String>.from(data!['StudentAssignBus'])
          : [],
    );
  }
}