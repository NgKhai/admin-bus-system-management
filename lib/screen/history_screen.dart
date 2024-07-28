import 'package:admin_bus_system_management/model/map_history_router.dart';
import 'package:admin_bus_system_management/model/route_data.dart';
import 'package:admin_bus_system_management/util/hex_color.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';

import '../model/bus_data.dart';
import '../util/constant.dart';

class HistoryScreen extends StatefulWidget {
  final BusData busData;

  const HistoryScreen({super.key, required this.busData});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<RoutesData> busRouteData = [];
  List<bool> _selectStates = [];
  List<RoutesData> forwardBusRouteData = [];
  List<RoutesData> backwardBusRouteData = [];
  int _selectedRoute = 0;
  final TextEditingController _searchController = TextEditingController();
  bool isLoading = true;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    getData();
  }

  Future<void> getData() async {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('Routes')
        .where('BusID', isEqualTo: widget.busData.busID)
        .get();

    setState(() {
      busRouteData = querySnapshot.docs
          .map((doc) => RoutesData.fromFirestore(doc))
          .toList();
      busRouteData.sort(_compareRoutes);
      _selectStates = List.generate(busRouteData.length, (index) => false);
      _sortBusRouteData();

      isLoading = false;
    });
  }

  int _compareRoutes(RoutesData a, RoutesData b) {
    DateTime dateA = _parseDate(a.currentDate);
    DateTime dateB = _parseDate(b.currentDate);
    int dateComparison = dateB.compareTo(dateA);
    if (dateComparison == 0) {
      DateTime timeA = _parseTime(a.busTime);
      DateTime timeB = _parseTime(b.busTime);
      return timeA.compareTo(timeB);
    }
    return dateComparison;
  }

  void _sortBusRouteData() {
    Set<String> forwardTimes = widget.busData.busForwardTime.toSet();

    for (final busRoute in busRouteData) {
      final busTime = busRoute.busTime;
      if (forwardTimes.contains(busTime)) {
        forwardBusRouteData.add(busRoute);
      } else {
        backwardBusRouteData.add(busRoute);
      }
    }
  }

  DateTime _parseDate(String date) {
    return DateFormat('dd/MM/yyyy').parse(date);
  }

  DateTime _parseTime(String time) {
    return DateFormat('HH:mm:ss').parse(time);
  }

  List<RoutesData> _filterRoutesByDateRange(List<RoutesData> routes) {
    if (_startDate == null || _endDate == null) {
      return routes;
    }

    return routes.where((route) {
      DateTime routeDate = _parseDate(route.currentDate);
      return routeDate.isAfter(_startDate!.subtract(Duration(days: 1))) &&
          routeDate.isBefore(_endDate!.add(Duration(days: 1)));
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
      // Custom help text
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Container(
        color: HexColor('#F2F1F6'),
        child: Column(
          children: [
            _buildRouteSelection(),
            Expanded(
              child: _buildRouteList(),
            ),
          ],
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
        widget.busData.busName,
        style: GoogleFonts.getFont(
          'Montserrat',
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 16,
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
                          onPressed: _searchController.clear,
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

  Widget _buildRouteSelection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.08,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRouteButton("Lượt đi", 0),
            _buildRouteButton("Lượt về", 1),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteButton(String title, int index) {
    return GestureDetector(
      onTap: () => setState(() {
        _selectedRoute = index;
      }),
      child: Container(
        margin: const EdgeInsets.all(5),
        width: MediaQuery.of(context).size.width * 0.4,
        height: MediaQuery.of(context).size.height * 0.2,
        decoration: BoxDecoration(
          color: _selectedRoute == index ? Colors.grey.shade50 : Colors.white,
          border: _selectedRoute == index
              ? Border.all(color: Constant.orangeHuflit, width: 3)
              : null,
          borderRadius: _selectedRoute == index
              ? BorderRadius.circular(15)
              : BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            title,
            style: GoogleFonts.getFont('Montserrat',
                fontWeight: FontWeight.bold,
                color: _selectedRoute == index ? Colors.black : Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else {
      List<RoutesData> filteredRoutes = _filterRoutesByDateRange(
          _selectedRoute == 0 ? forwardBusRouteData : backwardBusRouteData);

      if (filteredRoutes.isNotEmpty) {
        return ListView.builder(
          itemCount: filteredRoutes.length,
          itemBuilder: (context, index) {
            return _busItemRoute(filteredRoutes[index], index);
          },
        );
      } else {
        return Center(child: _dataText("Không tìm thấy dữ liệu"));
      }
    }
  }

  Widget _busItemRoute(RoutesData busRouteData, int index) {
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
              _buildRouteInfo(busRouteData, index),
              const SizedBox(height: 5),
              _buildStudentDetail(busRouteData, index),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRouteInfo(RoutesData busRouteData, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Ngày chạy: ', busRouteData.currentDate),
            const SizedBox(height: 5),
            _buildInfoRow('Giờ chạy: ', busRouteData.busTime),
            const SizedBox(height: 5),
            _buildInfoRow('Giờ bắt đầu: ', busRouteData.startTime),
            const SizedBox(height: 5),
            _buildInfoRow(
                'Giờ kết thúc: ', busRouteData.endTime ?? 'Mất dữ liệu'),
            const SizedBox(height: 5),
            _buildInfoRow(
              'Quãng đường: ',
              busRouteData.distance < 1
                  ? "${(busRouteData.distance * 1000).toStringAsFixed(0)} m"
                  : "${busRouteData.distance.toStringAsFixed(2)} km",
            ),
          ],
        ),
        FloatingActionButton(
          heroTag: null,
          backgroundColor: Constant.orangeHuflit,
          onPressed: () {
            context.push('/history/map_history',
                extra: MapHistoryRouterData(
                    busRouteData, busRouteData.positions.first));
          },
          child: const Icon(
            Icons.map_outlined,
            color: Colors.white,
          ),
        ),
      ],
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

  Widget _buildStudentDetail(RoutesData busRouteData, int index) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectStates[index] = !_selectStates[index];
        });
      },
      child: Column(
        children: [
          Row(
            children: [
              _selectStates[index]
                  ? const Icon(Icons.arrow_drop_down)
                  : const Icon(Icons.arrow_right),
              _defaultText('Tổng số sinh viên: '),
              _dataText("${busRouteData.studentDetail!.length} sinh viên"),
            ],
          ),
          if (_selectStates[index])
            Column(
              children: busRouteData.studentDetail!.map((student) {
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Constant.defaultScreen,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoRow('MSSV: ', student.studentID),
                              const SizedBox(height: 5),
                              _buildInfoRow(
                                  'Giờ xuống trạm: ', student.dropTime ?? ""),
                            ],
                          ),
                          FloatingActionButton(
                            heroTag: null,
                            backgroundColor: Constant.purpleHuflit,
                            onPressed: () {
                              context.push('/history/map_history',
                                  extra: MapHistoryRouterData(
                                      busRouteData,
                                      LatLng(student.dropLatitude.toDouble(),
                                          student.dropLongitude.toDouble())));
                            },
                            mini: true,
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
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
