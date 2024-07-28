
import 'package:admin_bus_system_management/model/attendance_data.dart';
import 'package:admin_bus_system_management/model/bus_data.dart';
import 'package:admin_bus_system_management/model/route_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../bloc/tracking/tracking_bloc.dart';
import '../bloc/tracking/tracking_event.dart';
import '../bloc/tracking/tracking_state.dart';
import '../model/student_data.dart';
import '../util/constant.dart';

class AddTracking extends StatefulWidget {
  final BusData busData;

  const AddTracking({super.key, required this.busData});

  @override
  State<AddTracking> createState() => _AddTrackingState();
}

class _AddTrackingState extends State<AddTracking> {
  String getDate(DateTime selectedDate) {
    return DateFormat('dd/MM/yyyy').format(selectedDate);
  }

  String getTime(DateTime selectedDate) {
    return DateFormat('HH:mm:ss').format(selectedDate);
  }

  String getFormatDuration(num minutes) {
    if (minutes < 1) {
      return "${(minutes * 60).toStringAsFixed(0)} giây";
    } else {
      int totalSeconds = (minutes * 60).floor();
      int minutesPart = totalSeconds ~/ 60;
      int secondsPart = totalSeconds % 60;
      String formattedDuration = '$minutesPart phút ';

      if (secondsPart > 0) {
        formattedDuration += '$secondsPart giây';
      }

      return "$formattedDuration ";
    }
  }

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _mapController.dispose();
  }

  Future<void> _addSampleStudentData(String busTime, LatLng lastDefaultRoute) async {

    final attendanceCollection =
    FirebaseFirestore.instance.collection('Attendances');
    AttendanceData attendanceData;

    for (int i = 0; i < 40; i++) {

      DocumentReference newDocRef = attendanceCollection.doc();

      if (i % 2 == 0) {
        attendanceData = AttendanceData(
          attendanceID: newDocRef.id,
          studentID: '21DH11${(1000 + i).toString().padLeft(4, '0')}',
          busID: widget.busData.busID,
          currentDate: getDate(DateTime.now()),
          currentTime: getTime(DateTime.now()),
          busTime: '11:00:00',
          dropLatitude: 10.814458579453676,
          dropLongitude: 106.6322300038695,
        );
      } else {
        attendanceData = AttendanceData(
          attendanceID: newDocRef.id,
          studentID: '21DH11${(1000 + i).toString().padLeft(4, '0')}',
          busID: widget.busData.busID,
          currentDate: getDate(DateTime.now()),
          currentTime: getTime(DateTime.now()),
          busTime: busTime,
          dropLatitude: lastDefaultRoute.latitude,
          dropLongitude: lastDefaultRoute.longitude,
        );
      }

      await newDocRef.set(attendanceData.toJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TrackingBloc(widget.busData),
      child: Scaffold(
        body: BlocConsumer<TrackingBloc, TrackingState>(
          listener: (context, state) {
            // Handle side effects here, such as showing a SnackBar, navigating, etc.
            if (state is TrackingStopped) {
              // Example of a side effect: Showing a SnackBar when tracking stops
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(CupertinoIcons.stop_circle,
                          color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Dừng chuyến đi thành công',
                          style: GoogleFonts.montserrat(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: Constant.purpleHuflit,
                  duration: const Duration(seconds: 3),
                  elevation: 4.0,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(4.0)),
                  ),
                  behavior: SnackBarBehavior.fixed,
                ),
              );
            }
          },
          builder: (context, state) {
            final bloc = BlocProvider.of<TrackingBloc>(context);
            List<LatLng> positions = [];
            double speed = 0.0;
            num duration = 0;
            num distance = 0;

            if (state is TrackingInProgress) {
              positions = state.positions;
              speed = state.speed;
              duration = state.duration;
              distance = state.distance;
            } else if (state is TrackingStopped) {
              positions = state.positions;
              speed = state.speed;
              duration = state.duration;
              distance = state.distance;
            }

            return Stack(
              alignment: AlignmentDirectional.bottomEnd,
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter:
                        const LatLng(10.865124963429814, 106.60061523787051),
                    initialZoom: 16,
                    maxZoom: 30,
                    onPositionChanged: (MapPosition position, bool hasGesture) {
                      if (hasGesture &&
                          bloc.alignPositionOnUpdate != AlignOnUpdate.never) {
                        bloc.alignPositionOnUpdate = AlignOnUpdate.never;
                        bloc.alignDirectionOnUpdate = AlignOnUpdate.never;
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: bloc.defaultRoute, // Use defaultRoute here
                          color: Colors.blue,
                          strokeWidth: 6,
                        ),
                        if (positions.isNotEmpty)
                          Polyline(
                            points: positions,
                            color: Constant.orangeHuflit,
                            strokeWidth: 8,
                          ),
                      ],
                    ),
                    CurrentLocationLayer(
                      alignPositionStream:
                          bloc.alignPositionStreamController.stream,
                      alignPositionOnUpdate: bloc.alignPositionOnUpdate,
                      alignDirectionOnUpdate: bloc.alignDirectionOnUpdate,
                      style: const LocationMarkerStyle(
                        marker: DefaultLocationMarker(
                          color: Constant.orangeHuflit,
                          child: Icon(
                            Icons.navigation,
                            color: Colors.white,
                          ),
                        ),
                        markerSize: Size(40, 40),
                        markerDirection: MarkerDirection.heading,
                      ),
                    ),
                    MarkerLayer(
                        rotate: true,
                        alignment: const Alignment(0.0, -0.25),
                        markers: bloc.markersDrop),
                  ],
                ),
                if (state is TrackingInProgress || state is TrackingStopped)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Constant.orangeHuflit,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Vận tốc: ',
                                  style: GoogleFonts.getFont(
                                    'Montserrat',
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  "${speed.toStringAsFixed(0)} km/h",
                                  style: GoogleFonts.getFont(
                                    'Montserrat',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Quãng đường: ',
                                  style: GoogleFonts.getFont(
                                    'Montserrat',
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  distance < 1
                                      ? "${(distance * 1000).toStringAsFixed(0)} m"
                                      : "${distance.toStringAsFixed(2)} km",
                                  style: GoogleFonts.getFont(
                                    'Montserrat',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Thời gian: ',
                                  style: GoogleFonts.getFont(
                                    'Montserrat',
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  getFormatDuration(duration),
                                  style: GoogleFonts.getFont(
                                    'Montserrat',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Giờ tuyến: ',
                                  style: GoogleFonts.getFont(
                                    'Montserrat',
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  bloc.busTime,
                                  style: GoogleFonts.getFont(
                                    'Montserrat',
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // add sample data
                if(state is TrackingInitial)
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, top: 20),
                      child: FloatingActionButton(
                        heroTag: UniqueKey(),
                        backgroundColor: Constant.purpleHuflit,
                        onPressed: () {
                          _addSampleStudentData(bloc.busTime, bloc.defaultRoute.last);
                        },
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 20, top: 20),
                    child: FloatingActionButton(
                      heroTag: UniqueKey(),
                      backgroundColor: Constant.orangeHuflit,
                      onPressed: () {
                        bloc.alignPositionOnUpdate = AlignOnUpdate.always;
                        bloc.alignDirectionOnUpdate = AlignOnUpdate.always;
                        bloc.alignPositionStreamController.add(18);
                      },
                      child: const Icon(
                        Icons.my_location,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: DraggableScrollableSheet(
                    initialChildSize: 0.35,
                    minChildSize: 0.35,
                    maxChildSize: 0.7,
                    builder: (BuildContext context,
                        ScrollController scrollController) {
                      return Container(
                        child: ListView.builder(
                            controller: scrollController,
                            itemCount: 1,
                            physics: (state is TrackingInitial)
                                ? const NeverScrollableScrollPhysics()
                                : null,
                            itemBuilder: (BuildContext context, int index) {
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Constant.orangeHuflit,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(40),
                                        topRight: Radius.circular(40),
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 20),
                                        SizedBox(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              5 /
                                              6,
                                          height: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.12,
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  state is TrackingInProgress
                                                      ? Constant.orangeHuflit
                                                      : Colors.white,
                                              foregroundColor:
                                                  state is TrackingInProgress
                                                      ? Colors.white
                                                      : Constant.orangeHuflit,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                side: const BorderSide(
                                                    color: Colors.white,
                                                    width: 2),
                                              ),
                                            ),
                                            onPressed: () {
                                              if (state
                                                  is! TrackingInProgress) {
                                                bloc.add(StartTracking());
                                              } else {
                                                String dropTime =
                                                    getTime(DateTime.now());
                                                for (int i = 0;
                                                    i <
                                                        bloc.studentDetailList
                                                            .length;
                                                    i++) {
                                                  if (bloc.studentDetailList[i]
                                                          .dropTime ==
                                                      null) {
                                                    bloc.studentDetailList[i] =
                                                        StudentDetail(
                                                            studentID: bloc
                                                                .studentDetailList[
                                                                    i]
                                                                .studentID,
                                                            dropLatitude: bloc
                                                                .studentDetailList[
                                                                    i]
                                                                .dropLatitude,
                                                            dropLongitude: bloc
                                                                .studentDetailList[
                                                                    i]
                                                                .dropLongitude,
                                                            dropTime: dropTime);
                                                  }
                                                }

                                                bloc.add(StopTracking());
                                              }
                                            },
                                            child: Text(
                                              state is TrackingInProgress
                                                  ? 'Dừng'
                                                  : 'Bắt đầu',
                                              style: GoogleFonts.getFont(
                                                'Montserrat',
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (state is TrackingInitial)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 20.0,
                                                vertical: 10.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0),
                                                  child: Text(
                                                    "Lượt đi",
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.getFont(
                                                      'Montserrat',
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                GridView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    itemCount: bloc
                                                        .forwardTimeList.length,
                                                    gridDelegate:
                                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 3,
                                                      crossAxisSpacing: 10.0,
                                                      mainAxisSpacing: 0.0,
                                                      childAspectRatio: 2,
                                                    ),
                                                    itemBuilder:
                                                        (context, index) {
                                                      final busTime =
                                                          bloc.forwardTimeList[
                                                              index];

                                                      return GestureDetector(
                                                        onTap: () {
                                                          bloc.add(
                                                              UpdateBusTime(
                                                                  busTime));
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: state.busTime ==
                                                                      busTime
                                                                  ? Colors.white
                                                                  : Constant
                                                                      .orangeHuflit,
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Text(
                                                              busTime,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: GoogleFonts
                                                                  .getFont(
                                                                'Montserrat',
                                                                color: state.busTime ==
                                                                        busTime
                                                                    ? Constant
                                                                        .orangeHuflit
                                                                    : Colors.grey[
                                                                        400],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          left: 8.0),
                                                  child: Text(
                                                    "Lượt về",
                                                    textAlign: TextAlign.center,
                                                    style: GoogleFonts.getFont(
                                                      'Montserrat',
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 16,
                                                    ),
                                                  ),
                                                ),
                                                GridView.builder(
                                                    shrinkWrap: true,
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    itemCount: bloc
                                                        .backwardTimeList
                                                        .length,
                                                    gridDelegate:
                                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                                      crossAxisCount: 3,
                                                      crossAxisSpacing: 10.0,
                                                      mainAxisSpacing: 0.0,
                                                      childAspectRatio: 2,
                                                    ),
                                                    itemBuilder:
                                                        (context, index) {
                                                      final busTime =
                                                          bloc.backwardTimeList[
                                                              index];

                                                      return GestureDetector(
                                                        onTap: () {
                                                          bloc.add(
                                                              UpdateBusTime(
                                                                  busTime));
                                                        },
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          child: Container(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            decoration:
                                                                BoxDecoration(
                                                              color: state.busTime ==
                                                                      busTime
                                                                  ? Colors.white
                                                                  : Constant
                                                                      .orangeHuflit,
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .white,
                                                                  width: 2),
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          8),
                                                            ),
                                                            child: Text(
                                                              busTime,
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: GoogleFonts
                                                                  .getFont(
                                                                'Montserrat',
                                                                color: state.busTime ==
                                                                        busTime
                                                                    ? Constant
                                                                        .orangeHuflit
                                                                    : Colors.grey[
                                                                        400],
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }),
                                                const SizedBox(height: 200),
                                              ],
                                            ),
                                          ),
                                        if (state is TrackingInProgress ||
                                            state is TrackingStopped)
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: GridView.builder(
                                                shrinkWrap: true,
                                                physics:
                                                    const NeverScrollableScrollPhysics(),
                                                gridDelegate:
                                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                                  crossAxisCount: 2,
                                                  crossAxisSpacing: 10.0,
                                                  mainAxisSpacing: 0.0,
                                                  childAspectRatio: 1.2,
                                                ),
                                                itemCount: bloc
                                                    .studentDetailList.length,
                                                itemBuilder: (context, index) {
                                                  final studentDetail = bloc
                                                      .studentDetailList[index];
                                                  bool isDrop = studentDetail
                                                              .dropLatitude
                                                              .toDouble() !=
                                                          bloc.defaultRoute.last
                                                              .latitude &&
                                                      studentDetail
                                                              .dropLongitude
                                                              .toDouble() !=
                                                          bloc.defaultRoute.last
                                                              .longitude;

                                                  return Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(8),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8),
                                                        ),
                                                        child: Column(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceEvenly,
                                                          children: [
                                                            Text(
                                                              studentDetail
                                                                  .studentID,
                                                              style:
                                                                  GoogleFonts
                                                                      .getFont(
                                                                'Montserrat',
                                                                color: Colors
                                                                    .black,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                            Text(
                                                              isDrop
                                                                  ? 'Trạm chỉ định'
                                                                  : 'Cuối trạm',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style:
                                                                  GoogleFonts
                                                                      .getFont(
                                                                'Montserrat',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Colors
                                                                    .black,
                                                                fontSize: 16,
                                                              ),
                                                            ),
                                                            if(isDrop)
                                                              ElevatedButton(
                                                                style: ElevatedButton
                                                                    .styleFrom(
                                                                  backgroundColor:
                                                                  Constant
                                                                      .purpleHuflit,
                                                                  foregroundColor:
                                                                  Colors
                                                                      .white,
                                                                  shape:
                                                                  RoundedRectangleBorder(
                                                                    borderRadius:
                                                                    BorderRadius.circular(
                                                                        12),
                                                                    side: const BorderSide(
                                                                        color: Colors
                                                                            .white,
                                                                        width:
                                                                        2),
                                                                  ),
                                                                ),
                                                                onPressed:
                                                                    () {
                                                                  _mapController.move(
                                                                      LatLng(
                                                                          studentDetail
                                                                              .dropLatitude
                                                                              .toDouble(),
                                                                          studentDetail
                                                                              .dropLongitude
                                                                              .toDouble()),
                                                                      16);
                                                                },
                                                                child: Text(
                                                                  'Xem vị trí',
                                                                  style: GoogleFonts
                                                                      .getFont(
                                                                    'Montserrat',
                                                                    fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                    fontSize:
                                                                    12,
                                                                  ),
                                                                ),
                                                              ),
                                                          ],
                                                        )),
                                                  );
                                                }),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
