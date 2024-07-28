import 'package:admin_bus_system_management/model/student_data.dart';
import 'package:admin_bus_system_management/util/constant.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../model/bus_data.dart';

class AddStudentScreen extends StatefulWidget {
  final List<BusData> busListData;

  const AddStudentScreen({super.key, required this.busListData});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final TextEditingController studentIDController = TextEditingController();
  final TextEditingController studentNameController = TextEditingController();
  final studentsCollection = FirebaseFirestore.instance.collection('Students');
  List<String> selectedBuses = [];

  Future<void> _saveStudent() async {
    if (studentIDController.text.isNotEmpty &&
        studentNameController.text.isNotEmpty &&
        selectedBuses.isNotEmpty) {

      // Check if the student document already exists
      bool isDocumentExists = await studentsCollection.doc(studentIDController.text).get().then((doc) => doc.exists);

      if (isDocumentExists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sinh viên ${studentIDController.text} đã tồn tại.',
              style: GoogleFonts.getFont(
                'Montserrat',
                fontSize: 14,
              ),
            ),
            backgroundColor: Constant.purpleHuflit,
          ),
        );
      } else {
        // Create StudentData object
        StudentData newStudent = StudentData(
          studentIDController.text,
          studentNameController.text,
          _getDate(DateTime.now()), // Date history
          selectedBuses,
        );

        // Save new student data to Firestore
        await studentsCollection.doc(studentIDController.text).set(newStudent.toJson()).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Thêm sinh viên ${studentIDController.text} thành công.',
                style: GoogleFonts.getFont(
                  'Montserrat',
                  fontSize: 14,
                ),
              ),
              backgroundColor: Constant.purpleHuflit,
            ),
          );

          context.go('/');
        }).catchError((error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Không thêm được sinh viên.',
              style: GoogleFonts.getFont(
                'Montserrat',
                fontSize: 14,
              ),
            ),
            backgroundColor: Constant.purpleHuflit,
          ),
        ));
      }
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

  String _getDate(DateTime selectedDate) {
    return DateFormat('dd/MM/yyyy').format(selectedDate);
  }

  @override
  void dispose() {
    // TODO: implement dispose

    studentIDController.dispose();
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
          "Thêm sinh viên",
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
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
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
              'Chọn tuyến xe',
              style: GoogleFonts.getFont(
                'Montserrat',
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ListView.builder(
                itemCount: widget.busListData.length,
                itemBuilder: (context, index) {
                  final bus = widget.busListData[index];
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
                _saveStudent();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Constant.orangeHuflit,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              child: Text(
                'Thêm sinh viên',
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
}
