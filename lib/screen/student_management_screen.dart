import 'package:admin_bus_system_management/model/student_buslist_data.dart';
import 'package:admin_bus_system_management/model/student_data.dart';
import 'package:admin_bus_system_management/model/bus_data.dart'; // Assuming you have a BusData model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../util/constant.dart';
import '../util/hex_color.dart';

class StudentManagementScreen extends StatefulWidget {
  final List<BusData> busListData;

  const StudentManagementScreen({super.key, required this.busListData});

  @override
  State<StudentManagementScreen> createState() =>
      _StudentManagementScreenState();
}

class _StudentManagementScreenState extends State<StudentManagementScreen> {
  final studentsCollection = FirebaseFirestore.instance.collection('Students');
  final removesCollection = FirebaseFirestore.instance.collection('Removes');
  final TextEditingController _searchController = TextEditingController();
  List<StudentData> studentListData = [];
  DateTime? _startDate;
  DateTime? _endDate;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    getStudentData();
  }

  Future<void> getStudentData() async {
    QuerySnapshot querySnapshot =
        await FirebaseFirestore.instance.collection('Students').get();

    setState(() {
      studentListData = querySnapshot.docs
          .map((doc) => StudentData.fromFirestore(doc))
          .toList();
      studentListData.sort(_compareStudentsByDate);
      isLoading = false;
    });
  }

  Future<void> _deleteStudent(StudentData student) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Xác nhận xóa',
            style:
                GoogleFonts.getFont('Montserrat', fontWeight: FontWeight.bold),
          ),
          content: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                    text: 'Bạn có chắc chắn muốn xóa sinh viên ',
                    style: GoogleFonts.getFont('Montserrat',
                        fontSize: 16,
                        color: Colors.black)),
                TextSpan(
                  text: student.studentID,
                  style: GoogleFonts.getFont('Montserrat',
                      fontSize: 16,
                      fontWeight: FontWeight.bold, color: Colors.black),
                ),
                TextSpan(
                    text: ' ?',
                    style: GoogleFonts.getFont('Montserrat',
                        fontSize: 16,
                        color: Colors.black)),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Hủy',
                style: GoogleFonts.getFont('Montserrat', color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                context.pop();
              },
            ),
            TextButton(
              child: Text(
                'Xóa',
                style: GoogleFonts.getFont('Montserrat', color: Colors.red, fontWeight: FontWeight.bold),
              ),
              onPressed: () {
                context.pop();
                _performDeleteStudent(student); // Proceed with the deletion
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _performDeleteStudent(StudentData student) async {

      // Save the deleted student's information into the Removes collection
      await removesCollection.add(student.toJson());

      await studentsCollection.doc(student.studentID).delete().then((value) async {
        // Remove the student from the local list
        setState(() {
          studentListData.removeWhere((s) => s.studentID == student.studentID);
        });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Xóa sinh viên ${student.studentID} thành công.',
            style: GoogleFonts.getFont(
              'Montserrat',
              fontSize: 14,
            ),
          ),
          backgroundColor: Constant.purpleHuflit,
        ),
      );
    }).catchError((error) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Không xóa được sinh viên.',
          style: GoogleFonts.getFont(
            'Montserrat',
            fontSize: 14,
          ),
        ),
        backgroundColor: Constant.purpleHuflit,
      ),
    ));
  }

  int _compareStudentsByDate(StudentData a, StudentData b) {
    DateTime dateA = _parseDate(a.dateHistory);
    DateTime dateB = _parseDate(b.dateHistory);
    return dateB.compareTo(dateA);
  }

  DateTime _parseDate(String date) {
    return DateFormat('dd/MM/yyyy').parse(date);
  }

  List<StudentData> _filterStudentsByName(String query) {
    if (query.isEmpty) {
      return studentListData;
    }
    String normalizedQuery = removeDiacritics(query).toLowerCase();
    return studentListData
        .where((student) => removeDiacritics(student.studentName)
            .toLowerCase()
            .contains(normalizedQuery))
        .toList();
  }

  List<StudentData> _filterStudentsByDateRange(
      List<StudentData> students, DateTime? startDate, DateTime? endDate) {
    if (startDate == null || endDate == null) {
      return students;
    }
    return students.where((student) {
      DateTime date = _parseDate(student.dateHistory);
      return date.isAfter(startDate.subtract(Duration(days: 1))) &&
          date.isBefore(endDate.add(Duration(days: 1)));
    }).toList();
  }

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now(),
        end: _endDate ?? DateTime.now(),
      ),
      helpText: 'Chọn khoảng thời gian',
      cancelText: 'Hủy',
      confirmText: 'Xác nhận',
      saveText: 'Lưu',
      fieldStartLabelText: 'Ngày bắt đầu',
      fieldStartHintText: 'Ngày bắt đầu',
      fieldEndLabelText: 'Ngày kết thúc',
      fieldEndHintText: 'Ngày kết thúc',
      errorFormatText: 'Vui lòng chọn ngày',
    );

    if (picked != null &&
        picked !=
            DateTimeRange(
                start: _startDate ?? DateTime.now(),
                end: _endDate ?? DateTime.now())) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        isLoading = true;
      });

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    // TODO: implement dispose

    _searchController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<StudentData> filteredStudents =
        _filterStudentsByName(_searchController.text);
    filteredStudents =
        _filterStudentsByDateRange(filteredStudents, _startDate, _endDate);

    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        color: HexColor('#F2F1F6'),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildStudentList(filteredStudents),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: UniqueKey(),
        backgroundColor: Constant.orangeHuflit,
        onPressed: () {
          context.push('/student_management/add_student',
              extra: widget.busListData);
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      leading: IconButton(
        color: Colors.white,
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onPressed: () => context.pop(),
      ),
      title: Text(
        "Quản lý sinh viên",
        style: GoogleFonts.getFont(
          'Montserrat',
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      titleTextStyle: GoogleFonts.getFont(
        'Montserrat',
        fontWeight: FontWeight.bold,
        fontSize: 24,
      ),
      backgroundColor: Constant.orangeHuflit,
      bottom: _buildSearchBar(context),
    );
  }

  PreferredSize _buildSearchBar(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(MediaQuery.of(context).size.height * 0.06),
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  hintStyle: GoogleFonts.getFont(
                    'Montserrat',
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.normal,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.zero,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(CupertinoIcons.clear_circled_solid)),
                ),
                onChanged: (value) => setState(() {}),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.calendar_month),
              color: Colors.white,
              onPressed: () => _selectDateRange(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentList(List<StudentData> students) {
    if (students.isEmpty) {
      return Center(child: _dataText("Không tìm thấy dữ liệu"));
    }

    return ListView.builder(
      itemCount: students.length,
      itemBuilder: (context, index) {
        return _studentItem(students[index]);
      },
    );
  }

  Widget _studentItem(StudentData studentData) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildInfoRow('MSSV: ', studentData.studentID),
                      const SizedBox(height: 5),
                      _buildInfoRow('Tên sinh viên: ', studentData.studentName),
                      const SizedBox(height: 5),
                      _buildInfoRow('Ngày đăng ký: ', studentData.dateHistory),
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue, // Adjust color as needed
                        ),
                        // Set a smaller size for the container
                        height: 40.0, // Adjust height and width as needed
                        width: 40.0, // Adjust height and width as needed
                        child: IconButton(
                          icon: const Icon(Icons.edit_note,
                              size: 20, color: Colors.white),
                          onPressed: () {
                            context.push('/student_management/update_student',
                                extra: StudentBusListData(
                                    studentData, widget.busListData));
                          },
                        ),
                      ),
                      const SizedBox(height: 5),
                      Container(
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.red, // Adjust color as needed
                        ),
                        height: 40.0, // Adjust height and width as needed
                        width: 40.0, // Adjust height and width as needed
                        child: IconButton(
                          icon: const Icon(Icons.close,
                              size: 20, color: Colors.white),
                          onPressed: () =>
                              _deleteStudent(studentData),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 5),
              _buildBusAssignmentsRow(studentData.studentAssignBus),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        _defaultText(label),
        _dataText(value),
      ],
    );
  }

  Widget _buildBusAssignmentsRow(List<String> busIds) {
    List<String> busNames = [];
    for (String busId in busIds) {
      BusData? bus = widget.busListData.firstWhere((bus) => bus.busID == busId);
      busNames.add("\u2022 ${bus.busName}");
    }
    String busAssignments = busNames.join('\n ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _defaultText('Tuyến xe đã đăng ký: '),
        _dataText(busAssignments),
      ],
    );
  }

  Text _defaultText(String title) {
    return Text(
      title,
      style: GoogleFonts.getFont(
        'Montserrat',
        color: Colors.black,
        fontSize: 16.0,
        fontWeight: FontWeight.normal,
        letterSpacing: 0.6,
      ),
    );
  }

  Text _dataText(String title) {
    return Text(
      title,
      style: GoogleFonts.getFont(
        'Montserrat',
        color: Colors.black,
        fontSize: 16.0,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.6,
      ),
    );
  }
}
