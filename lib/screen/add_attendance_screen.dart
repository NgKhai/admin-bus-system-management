import 'package:admin_bus_system_management/model/student_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../model/attendance_data.dart';
import '../model/bus_data.dart';
import '../util/constant.dart';

import 'package:xml/xml.dart' as xml;

class AddAttendanceScreen extends StatefulWidget {
  final String studentID;

  const AddAttendanceScreen({super.key, required this.studentID});

  @override
  State<AddAttendanceScreen> createState() => _AddAttendanceScreenState();
}

class _AddAttendanceScreenState extends State<AddAttendanceScreen> {
  final studentCollection = FirebaseFirestore.instance.collection('Students');
  final busCollection = FirebaseFirestore.instance.collection('Bus');
  final attendanceCollection =
      FirebaseFirestore.instance.collection('Attendances');
  String? gpx;
  List<LatLng> defaultRoute = [];
  StudentData? studentData;
  List<BusData> busListData = [];

  int selectedBus = -1;
  int selectedForwardTime = -1;
  int selectedBackwardTime = -1;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    await getStudentData();
    await getBusListData();
    setState(() {});
  }

  Future<void> getStudentData() async {
    DocumentSnapshot documentSnapshot =
        await studentCollection.doc(widget.studentID).get();

    studentData = StudentData.fromFirestore(documentSnapshot);
  }

  Future<void> getBusListData() async {
    for (int i = 0; i < studentData!.studentAssignBus.length; i++) {
      QuerySnapshot querySnapshot = await busCollection
          .where('BusID', isEqualTo: studentData!.studentAssignBus[i])
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        busListData.addAll(
            querySnapshot.docs.map((doc) => BusData.fromFirestore(doc)));
      }
    }
  }

  String _getGpx(String busID) {
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

    return selectedForwardTime != -1
        ? forwardRoutes[busID] ?? ''
        : backwardRoutes[busID] ?? '';
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

  Future<void> saveAttendanceData(String busID) async {
      String busTime = selectedForwardTime != -1
          ? busListData[selectedBus].busForwardTime[selectedForwardTime]
          : busListData[selectedBus].busBackwardTime[selectedBackwardTime];

      bool attendanceExist = await isAttendanceExist(widget.studentID, busID, getDate(DateTime.now()), busTime);

      if(attendanceExist) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sinh viên đã điểm danh ${busListData[selectedBus].busName} vào lúc $busTime.',
              style: GoogleFonts.getFont(
                'Montserrat',
                fontSize: 14,
              ),
            ),
            backgroundColor: Constant.purpleHuflit,
          ),
        );
      } else {
        gpx = _getGpx(busID);

        defaultRoute = await parseGpx('assets/routes/$gpx.gpx');

        DocumentReference newDocRef = attendanceCollection.doc();

        AttendanceData attendanceData = AttendanceData(
          attendanceID: newDocRef.id,
          studentID: widget.studentID,
          busID: busID,
          currentDate: getDate(DateTime.now()),
          currentTime: getTime(DateTime.now()),
          busTime: busTime,
          dropLatitude: defaultRoute.last.latitude,
          dropLongitude: defaultRoute.last.longitude,
        );

        await newDocRef.set(attendanceData.toJson()).then((value) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Điểm danh sinh viên ${widget.studentID} thành công.',
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
              'Không điểm danh được sinh viên.',
              style: GoogleFonts.getFont(
                'Montserrat',
                fontSize: 14,
              ),
            ),
            backgroundColor: Constant.purpleHuflit,
          ),
        ));
      }
  }

  Future<bool> isAttendanceExist(String studentID, String busID, String currentDate, String busTime) async {
    try {
      final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('Attendances')
          .where('StudentID', isEqualTo: studentID)
          .where('BusID', isEqualTo: busID)
          .where('CurrentDate', isEqualTo: currentDate)
          .where('BusTime', isEqualTo: busTime)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      // Handle errors
      print('Error checking attendance existence: $e');
      return false;
    }
  }

  String getDate(DateTime selectedDate) {
    return DateFormat('dd/MM/yyyy').format(selectedDate);
  }

  String getTime(DateTime selectedDate) {
    return DateFormat('HH:mm:ss').format(selectedDate);
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
          "Quét mặt điểm danh",
          style: GoogleFonts.getFont(
            'Montserrat',
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        backgroundColor: Constant.orangeHuflit,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Text(
                "Thông tin sinh viên",
                style: GoogleFonts.getFont(
                  'Montserrat',
                  color: Constant.kDarkBlue,
                  fontSize: 24.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mã số sinh viên: ${studentData?.studentID ?? ""}",
                  style: GoogleFonts.getFont(
                    'Montserrat',
                    color: Constant.kDarkBlue,
                    fontSize: 18.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Họ và tên: ${studentData?.studentName ?? ""}",
                  style: GoogleFonts.getFont(
                    'Montserrat',
                    color: Constant.kDarkBlue,
                    fontSize: 18.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  "Điểm danh tuyến: ${selectedBus != -1 ? busListData[selectedBus].busName : "Vui lòng chọn tuyến xe"}",
                  style: GoogleFonts.getFont(
                    'Montserrat',
                    color: Constant.kDarkBlue,
                    fontSize: 18.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
                const SizedBox(height: 5),
                if (selectedForwardTime != -1)
                  Text(
                    "Giờ khởi hành: ${busListData[selectedBus].busForwardTime[selectedForwardTime]}",
                    style: GoogleFonts.getFont(
                      'Montserrat',
                      color: Constant.kDarkBlue,
                      fontSize: 18.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                if (selectedBackwardTime != -1)
                  Text(
                    "Giờ khởi hành: ${busListData[selectedBus].busBackwardTime[selectedBackwardTime]}",
                    style: GoogleFonts.getFont(
                      'Montserrat',
                      color: Constant.kDarkBlue,
                      fontSize: 18.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                if (selectedForwardTime == -1 && selectedBackwardTime == -1)
                  Text(
                    "Giờ khởi hành: Vui lòng chọn giờ khởi hành",
                    style: GoogleFonts.getFont(
                      'Montserrat',
                      color: Constant.kDarkBlue,
                      fontSize: 18.0,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
              ],
            ),
          ),
          Wrap(
            direction: Axis.vertical,
            children: busListData.map((busData) {
              int index = busListData.indexOf(busData);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selectedBus = index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    width: MediaQuery.of(context).size.width - 16,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: index == selectedBus
                          ? Constant.orangeHuflit
                          : Colors.white,
                      border:
                          Border.all(color: Constant.orangeHuflit, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        busData.busName,
                        style: GoogleFonts.getFont(
                          'Montserrat',
                          color: index == selectedBus
                              ? Colors.white
                              : Constant.orangeHuflit,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (selectedBus != -1) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Lượt đi",
                style: GoogleFonts.getFont(
                  'Montserrat',
                  color: Constant.orangeHuflit,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Number of columns in the grid
                    crossAxisSpacing: 3.0,
                    mainAxisSpacing: 3.0,
                  ),
                  itemCount: busListData[selectedBus].busForwardTime.length,
                  itemBuilder: (context, index) {
                    final busForwardTime =
                        busListData[selectedBus].busForwardTime;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedForwardTime = index;
                          selectedBackwardTime = -1;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: index == selectedForwardTime
                                ? Constant.orangeHuflit
                                : Colors.white,
                            border: Border.all(
                                color: Constant.orangeHuflit, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              busForwardTime[index],
                              style: GoogleFonts.getFont(
                                'Montserrat',
                                color: index == selectedForwardTime
                                    ? Colors.white
                                    : Constant.orangeHuflit,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Lượt về",
                style: GoogleFonts.getFont(
                  'Montserrat',
                  color: Constant.orangeHuflit,
                  fontSize: 16.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // Number of columns in the grid
                    crossAxisSpacing: 3.0,
                    mainAxisSpacing: 3.0,
                  ),
                  itemCount: busListData[selectedBus].busBackwardTime.length,
                  itemBuilder: (context, index) {
                    final busBackwardTime =
                        busListData[selectedBus].busBackwardTime;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedForwardTime = -1;
                          selectedBackwardTime = index;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: index == selectedBackwardTime
                                ? Constant.orangeHuflit
                                : Colors.white,
                            border: Border.all(
                                color: Constant.orangeHuflit, width: 2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              busBackwardTime[index],
                              style: GoogleFonts.getFont(
                                'Montserrat',
                                color: index == selectedBackwardTime
                                    ? Colors.white
                                    : Constant.orangeHuflit,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
          if (selectedForwardTime != -1 || selectedBackwardTime != -1)
            Center(
              child: Padding(
                padding:
                    const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 16.0),
                child: Container(
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Constant.orangeHuflit,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      saveAttendanceData(busListData[selectedBus].busID);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Điểm danh',
                      style: GoogleFonts.getFont(
                        'Montserrat',
                        fontSize: 16,
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
