import 'package:admin_bus_system_management/model/student_buslist_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/student_data.dart';
import '../util/constant.dart';

class UpdateStudentScreen extends StatefulWidget {

  final StudentBusListData studentBusListData;

  const UpdateStudentScreen({super.key, required this.studentBusListData});

  @override
  State<UpdateStudentScreen> createState() => _UpdateStudentScreenState();
}

class _UpdateStudentScreenState extends State<UpdateStudentScreen> {
  final TextEditingController studentIDController = TextEditingController();
  final TextEditingController dateHistoryController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();
  List<String> selectedBuses = [];

  final studentsCollection = FirebaseFirestore.instance.collection('Students');

  @override
  void initState() {
    super.initState();
    // Pre-fill the fields with the current student data
    studentIDController.text = widget.studentBusListData.studentData.studentID;
    dateHistoryController.text = widget.studentBusListData.studentData.dateHistory;
    studentNameController.text = widget.studentBusListData.studentData.studentName;
    selectedBuses = widget.studentBusListData.studentData.studentAssignBus;
  }

  @override
  void dispose() {
    // TODO: implement dispose

    studentIDController.dispose();
    dateHistoryController.dispose();
    studentNameController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          color: Colors.white,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Cập nhật thông tin sinh viên",
          style: GoogleFonts.getFont(
            'Montserrat',
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),

        backgroundColor: Constant.orangeHuflit,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: studentIDController,
              decoration: InputDecoration(
                labelText: 'Mã số sinh viên',
                labelStyle: GoogleFonts.getFont(
                  'Montserrat',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              style: GoogleFonts.getFont(
                'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
              ),
              readOnly: true, // Make ID field read-only
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: dateHistoryController,
              decoration: InputDecoration(
                labelText: 'Ngày tạo',
                labelStyle: GoogleFonts.getFont(
                  'Montserrat',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              style: GoogleFonts.getFont(
                'Montserrat',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.grey,
              ),
              readOnly: true, // Make ID field read-only
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: studentNameController,
              decoration: InputDecoration(
                labelText: 'Tên sinh viên',
                labelStyle: GoogleFonts.getFont(
                  'Montserrat',
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              style: GoogleFonts.getFont(
                'Montserrat',
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16.0),
            Text(
              'Chọn xe buýt',
              style: GoogleFonts.getFont(
                'Montserrat',
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount: widget.studentBusListData.busListData.length,
                itemBuilder: (context, index) {
                  final bus = widget.studentBusListData.busListData[index];
                  return CheckboxListTile(
                    title: Text(
                      bus.busName,
                      style: GoogleFonts.getFont(
                        'Montserrat',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                    value: selectedBuses.contains(bus.busID),
                    onChanged: (bool? value) {
                      setState(() {
                        if (value != null && value) {
                          selectedBuses.add(bus.busID);
                        } else {
                          selectedBuses.remove(bus.busID);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                _updateStudent();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constant.orangeHuflit,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'Cập nhật sinh viên',
                style: GoogleFonts.getFont(
                  'Montserrat',
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateStudent() async {
    if (studentIDController.text.isNotEmpty &&
        studentNameController.text.isNotEmpty &&
        selectedBuses.isNotEmpty) {
      // Create StudentData object with updated data
      StudentData updatedStudent = StudentData(
        studentIDController.text,
        studentNameController.text,
        widget.studentBusListData.studentData.dateHistory,
        selectedBuses,
      );

      // Update student data in Firestore
      await studentsCollection.doc(studentIDController.text).update(updatedStudent.toJson()).then((value) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cập nhật thông tin sinh viên ${studentIDController.text} thành công.',
              style: GoogleFonts.getFont(
                'Montserrat',
                fontSize: 14,
              ),
            ),
            backgroundColor: Constant.purpleHuflit,
          ),
        );

        context.go("/");
      }).catchError((error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không cập nhật được thông tin sinh viên.',
            style: GoogleFonts.getFont(
              'Montserrat',
              fontSize: 14,
            ),
          ),
          backgroundColor: Constant.purpleHuflit,
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vui lòng điền đầy đủ thông tin và chọn ít nhất một tuyến xe.',
            style: GoogleFonts.getFont(
              'Montserrat',
              fontSize: 14,
            ),
          ),
          backgroundColor: Constant.purpleHuflit,
        ),
      );
    }
  }
}
