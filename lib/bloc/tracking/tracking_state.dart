import 'package:equatable/equatable.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

abstract class TrackingState extends Equatable {
  const TrackingState();

  @override
  List<Object> get props => [];
}

class TrackingInitial extends TrackingState {
  final List<LatLng> defaultRoute;
  final List<Marker> markersDrop;
  final String busTime;

  TrackingInitial({this.defaultRoute = const [], this.markersDrop = const [], this.busTime = '00:00:00'});

  @override
  List<Object> get props => [defaultRoute, markersDrop, busTime];
}

class TrackingInProgress extends TrackingState {
  final List<LatLng> positions;
  final double speed;
  final num duration;
  final num distance;

  const TrackingInProgress({
    required this.positions,
    required this.speed,
    required this.duration,
    required this.distance,
  });

  @override
  List<Object> get props => [positions, speed, duration, distance];
}

class TrackingStopped extends TrackingState {
  final List<LatLng> positions;
  final double speed;
  final num duration;
  final num distance;

  const TrackingStopped({
    required this.positions,
    required this.speed,
    required this.duration,
    required this.distance,
  });

  @override
  List<Object> get props => [positions, speed, duration, distance];
}
