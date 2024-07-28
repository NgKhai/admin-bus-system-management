import 'package:admin_bus_system_management/util/constant.dart';
import 'package:admin_bus_system_management/util/hex_color.dart';
import 'package:admin_bus_system_management/widget/bus_info_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../model/bus_data.dart';
import '../widget/bus_list_widget.dart';
import '../widget/top_container.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  static CircleAvatar calendarIcon() {
    return const CircleAvatar(
      radius: 25.0,
      backgroundColor: Constant.kGreen,
      child: Icon(
        Icons.calendar_today,
        size: 20.0,
        color: Colors.white,
      ),
    );
  }

  Text subheading(String title) {
    return Text(
      title,
      style: GoogleFonts.getFont(
          'Montserrat',
          color: Constant.kDarkBlue,
          fontSize: 20.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
      ),
    );
  }

  late List<BusData> busListData = [];

  @override
  void initState() {
    // TODO: implement initState

    getData();

    super.initState();
  }

  Future<bool> getData() async {
    // await Future<dynamic>.delayed(const Duration(milliseconds: 50));
    // return true;

    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Bus')
        .get();
    setState(() {
      busListData = querySnapshot.docs.map((doc) => BusData.fromFirestore(doc)).toList();
    });

    return true;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: HexColor('#F2F1F6'),
      body: Column(
        children: <Widget>[
          TopContainer(
            height: MediaQuery.of(context).size.height * 1/6,
            width: width,
            padding: EdgeInsets.zero,
            child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      Image.asset('assets/images/logo.jpg', height: 100,),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("HUFLIT ",
                                style: GoogleFonts.getFont(
                                  'Montserrat',
                                  fontSize: 40,
                                  color: Constant.orangeHuflit,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text("BUS",
                                style: GoogleFonts.getFont(
                                  'Montserrat',
                                  fontSize: 40,
                                  color: Constant.purpleHuflit,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            child: Text(
                              'Đi đúng giờ, về đúng lúc',
                              textAlign: TextAlign.start,
                              style: GoogleFonts.getFont(
                                'Montserrat',
                                fontSize: 16.0,
                                color: Colors.black45,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                ]),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        GestureDetector(
                          onTap: () => context.go('/student_management', extra: busListData),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Constant.orangeHuflit,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.white10, width: 2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.person_2_rounded, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Quản lý sinh viên",
                                        textAlign: TextAlign.start,
                                        style: GoogleFonts.getFont(
                                          'Montserrat',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/face_recognition'),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Constant.purpleHuflit,
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(color: Colors.white10, width: 2),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(15.0),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.photo_camera_front_outlined, color: Colors.white),
                                      const SizedBox(width: 10),
                                      Text(
                                        "Quét mặt điểm danh",
                                        textAlign: TextAlign.start,
                                        style: GoogleFonts.getFont(
                                          'Montserrat',
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        subheading('Các Tuyến Xe'),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: busListData.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 20.0,
                            mainAxisSpacing: 0.0,
                            childAspectRatio: 0.75,
                          ),
                          itemBuilder: (context, index) {
                            BusData busData = busListData[index];
                            return BusListWidget(
                              busData: busData,
                              onTap: () {
                                context.push('/addTracking', extra: busData); // Assuming BusData has an id field
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0, vertical: 10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        subheading('Thông Tin Tuyến Xe'),
                        ListView.builder(shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: busListData.length,
                            itemBuilder: (context, index) {
                              final busData = busListData[index];
                              return BusInfoWidget(busData: busData, onTap: () {
                                context.go('/history', extra: busData); // Assuming BusData has an id field
                              },);

                        })
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
