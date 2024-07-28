import 'package:admin_bus_system_management/model/route_data.dart';
import 'package:latlong2/latlong.dart';

class MapHistoryRouterData {
  final RoutesData busRouteData;
  final LatLng initialMarker;

  const MapHistoryRouterData(this.busRouteData, this.initialMarker);
}