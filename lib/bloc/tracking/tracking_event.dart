import 'package:equatable/equatable.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';

abstract class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object> get props => [];
}

class StartTracking extends TrackingEvent {}

class StopTracking extends TrackingEvent {}

class UpdateTracking extends TrackingEvent {
  final LatLng position;
  final double speed;
  final DateTime startTime;

  const UpdateTracking({
    required this.position,
    required this.speed,
    required this.startTime,
  });

  @override
  List<Object> get props => [position, speed, startTime];
}

class UpdateBusTime extends TrackingEvent {
  final String busTime;

  const UpdateBusTime(this.busTime);

  @override
  List<Object> get props => [busTime];
}