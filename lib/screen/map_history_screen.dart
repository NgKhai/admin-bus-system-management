import 'package:admin_bus_system_management/model/map_history_router.dart';
import 'package:admin_bus_system_management/model/route_data.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../util/constant.dart';

class MapHistoryScreen extends StatefulWidget {
  final MapHistoryRouterData mapData;

  const MapHistoryScreen({super.key, required this.mapData});

  @override
  State<MapHistoryScreen> createState() => _MapHistoryScreenState();
}

class _MapHistoryScreenState extends State<MapHistoryScreen> {
  late RoutesData routeData;
  final MapController _mapController = MapController();

  List<Marker> markers = [];

  @override
  void initState() {
    super.initState();

    fetchData();
  }

  fetchData() {
    routeData = widget.mapData.busRouteData;

    _getMarkerInitial();
    _getStudentMarker();
  }

  _getMarkerInitial() {
    // Start marker
    markers.add(Marker(
      point: routeData.positions.first,
      child: const Icon(
        Icons.directions_bus,
        color: Constant.purpleHuflit,
        size: 40,
      ),
    ));

    // Destination marker
    markers.add(Marker(
      point: routeData.positions.last,
      child: const Icon(
        CupertinoIcons.map_pin_ellipse,
        color: Constant.purpleHuflit,
        size: 40,
      ),
    ));
  }

  _getStudentMarker() {
    final studentDetail = routeData.studentDetail;
    if(studentDetail != null) {
      for(int i = 0; i < studentDetail.length; i++) {
        markers.add(
          Marker(
            width: 100,
            height: 100,
            point: LatLng(studentDetail[i].dropLatitude.toDouble(),
                studentDetail[i].dropLongitude.toDouble()),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: Constant.blueHuflit,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    studentDetail[i].studentID,
                    style: GoogleFonts.getFont(
                      'Montserrat',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Icon(
                  Icons.place,
                  color: Constant.blueHuflit,
                  size: 40,
                ),
              ],
            ),
          ),
        );
      }
    }
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
          'Lịch trình di chuyển',
          style: GoogleFonts.getFont(
            'Montserrat',
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        backgroundColor: Constant.orangeHuflit,
      ),
      body: Stack(children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: widget.mapData.initialMarker,
            initialZoom: 16,
            maxZoom: 30,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            ),
            PolylineLayer(
              polylines: [
                // Polyline(
                //   points: widget.busRoute.positions, // Use defaultRoute here
                //   color: Colors.blue,
                //   strokeWidth: 6,
                // ),
                if (routeData.positions.isNotEmpty)
                  Polyline(
                    points: routeData.positions,
                    color: Constant.orangeHuflit,
                    strokeWidth: 8,
                  ),
              ],
            ),
            MarkerLayer(
                rotate: true,
                alignment: const Alignment(0.0, -0.25),
                markers: markers),
          ],
        ),
      ]),
    );
  }
}
