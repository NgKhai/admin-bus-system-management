import 'package:equatable/equatable.dart';

abstract class FaceRecognitionEvent extends Equatable {
  const FaceRecognitionEvent();

  @override
  List<Object?> get props => [];
}

class InitializeCameraEvent extends FaceRecognitionEvent {}

class SwitchCameraEvent extends FaceRecognitionEvent {}

class ToggleFlashEvent extends FaceRecognitionEvent {}

class CaptureAndSendImageEvent extends FaceRecognitionEvent {}

class UpdateResultEvent extends FaceRecognitionEvent {
  final String result;

  const UpdateResultEvent(this.result);

  @override
  List<Object?> get props => [result];
}