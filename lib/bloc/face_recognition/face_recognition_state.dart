import 'package:equatable/equatable.dart';
import 'package:camera/camera.dart';

abstract class FaceRecognitionState extends Equatable {
  const FaceRecognitionState();

  @override
  List<Object?> get props => [];
}

class FaceRecognitionInitial extends FaceRecognitionState {}

class CameraInitialized extends FaceRecognitionState {
  final CameraController cameraController;
  final bool isFlashOn;
  final String result;

  const CameraInitialized(this.cameraController, this.isFlashOn, this.result);

  @override
  List<Object?> get props => [cameraController, isFlashOn, result];
}

class FaceRecognitionSuccess extends FaceRecognitionState {

  final String studentID;

  const FaceRecognitionSuccess(this.studentID);

  @override
  List<Object?> get props => [studentID];
}