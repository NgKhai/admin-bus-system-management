import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:camera/camera.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'face_recognition_event.dart';
import 'face_recognition_state.dart';

class FaceRecognitionBloc extends Bloc<FaceRecognitionEvent, FaceRecognitionState> {
  List<CameraDescription>? cameras;
  CameraController? cameraController;
  IO.Socket? socket;
  bool isFlashOn = false;
  int selectedCameraIndex = 0;
  String result = "Đang chờ kết nối...";

  FaceRecognitionBloc() : super(FaceRecognitionInitial()) {
    on<InitializeCameraEvent>(_onInitializeCamera);
    on<SwitchCameraEvent>(_onSwitchCamera);
    on<ToggleFlashEvent>(_onToggleFlash);
    on<CaptureAndSendImageEvent>(_onCaptureAndSendImage);
    on<UpdateResultEvent>(_onUpdateResult);
  }

  Future<void> _onInitializeCamera(
      InitializeCameraEvent event, Emitter<FaceRecognitionState> emit) async {
    cameras = await availableCameras();
    if (cameras!.isNotEmpty) {
      cameraController =
          CameraController(cameras![selectedCameraIndex], ResolutionPreset.high);
      await cameraController!.initialize();
      emit(CameraInitialized(cameraController!, isFlashOn, result));
    }
    _initializeSocket();
  }

  Future<void> _onSwitchCamera(
      SwitchCameraEvent event, Emitter<FaceRecognitionState> emit) async {
    selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
    cameraController =
        CameraController(cameras![selectedCameraIndex], ResolutionPreset.high);
    await cameraController!.initialize();
    emit(CameraInitialized(cameraController!, isFlashOn, result));
  }

  Future<void> _onToggleFlash(
      ToggleFlashEvent event, Emitter<FaceRecognitionState> emit) async {
    if (cameraController != null && cameraController!.value.isInitialized) {
      isFlashOn = !isFlashOn;
      await cameraController!
          .setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
      emit(CameraInitialized(cameraController!, isFlashOn, result));
    }
  }

  Future<void> _onCaptureAndSendImage(
      CaptureAndSendImageEvent event, Emitter<FaceRecognitionState> emit) async {
    if (cameraController != null && cameraController!.value.isInitialized) {
      final image = await cameraController!.takePicture();
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      socket!.emit('image', 'data:image/jpeg;base64,$base64Image');
    }
  }

  void _onUpdateResult(UpdateResultEvent event, Emitter<FaceRecognitionState> emit) {
    result = event.result;
    emit(CameraInitialized(cameraController!, isFlashOn, result));
  }

  void _initializeSocket() {

    print("Hello world !!!!!!!!!!!!!!!!!");

    socket = IO.io('http://192.168.1.102:5000',
        IO.OptionBuilder().setTransports(['websocket']).build());

    socket!.onConnect((_) {
      add(const UpdateResultEvent("Kết nối thành công"));
    });

    socket!.on('result', (data) {
      final newResult = data['matches']
          ? "MSSV: ${data['student_id']}"
          : "Không tìm thấy sinh viên";
      add(UpdateResultEvent(newResult));
      if (data['matches']) {
        // Navigate to another screen upon successful capture
        emit(FaceRecognitionSuccess(data['student_id']));
      }
    });

    socket!.onDisconnect((_) {
      add(const UpdateResultEvent("Ngắt kết nối"));
    });
  }

  void _disposeSocket() {
    if (socket != null) {
      socket!.disconnect();
      socket!.dispose();
      socket = null;
    }
  }

  @override
  Future<void> close() {
    _disposeSocket();
    cameraController?.dispose();
    return super.close();
  }
}
