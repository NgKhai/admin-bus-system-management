// import 'dart:convert';
// import 'dart:io';
//
// import 'package:camera/camera.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:socket_io_client/socket_io_client.dart' as IO;
//
// import '../util/constant.dart';
//
// class FaceRecognitionScreen extends StatefulWidget {
//   const FaceRecognitionScreen({super.key});
//
//   @override
//   State<FaceRecognitionScreen> createState() => _FaceRecognitionScreenState();
// }
//
// class _FaceRecognitionScreenState extends State<FaceRecognitionScreen> {
//   CameraController? cameraController;
//   List<CameraDescription>? cameras;
//   IO.Socket? socket;
//   String result = "Không tìm thấy sinh viên";
//   bool isFlashOn = false;
//   int selectedCameraIndex = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     initializeCamera();
//     initializeSocket();
//   }
//
//   void initializeCamera() async {
//     cameras = await availableCameras();
//     if (cameras!.isNotEmpty) {
//       cameraController = CameraController(cameras![selectedCameraIndex], ResolutionPreset.high);
//       await cameraController!.initialize();
//       setState(() {});
//     }
//   }
//
//   void switchCamera() async {
//     selectedCameraIndex = (selectedCameraIndex + 1) % cameras!.length;
//     cameraController = CameraController(cameras![selectedCameraIndex], ResolutionPreset.high);
//     await cameraController!.initialize();
//     setState(() {});
//   }
//
//   void toggleFlash() async {
//     if (cameraController != null && cameraController!.value.isInitialized) {
//       isFlashOn = !isFlashOn;
//       await cameraController!.setFlashMode(isFlashOn ? FlashMode.torch : FlashMode.off);
//       setState(() {});
//     }
//   }
//
//   void initializeSocket() {
//     socket = IO.io('http://192.168.1.109:5000',
//         IO.OptionBuilder().setTransports(['websocket']).build());
//
//     socket!.onConnect((_) {
//       setState(() {
//         result = "Kết nối thành công";
//       });
//     });
//
//     socket!.on('result', (data) {
//       setState(() {
//         result = data['matches']
//             ? "MSSV: ${data['student_id']}"
//             : "Không tìm thấy sinh viên";
//       });
//     });
//
//     socket!.onDisconnect((_) {
//       setState(() {
//         result = "Ngắt kết nối";
//       });
//     });
//   }
//
//   void captureAndSendImage() async {
//     if (cameraController != null && cameraController!.value.isInitialized) {
//       print("Captured!!!!");
//       final image = await cameraController!.takePicture();
//       final bytes = await image.readAsBytes();
//       final base64Image = base64Encode(bytes);
//       socket!.emit('image', 'data:image/jpeg;base64,$base64Image');
//     }
//   }
//
//   @override
//   void dispose() {
//     cameraController?.dispose();
//     socket?.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (cameraController == null || !cameraController!.value.isInitialized) {
//       return Center(child: CircularProgressIndicator());
//     }
//
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           color: Colors.white,
//           icon: const Icon(Icons.arrow_back_ios_new_rounded),
//           splashColor: Colors.transparent,
//           highlightColor: Colors.transparent,
//           onPressed: () => context.pop(),
//         ),
//         title: Text(
//           "Điểm danh nhận diện khuôn mặt",
//           style: GoogleFonts.getFont(
//             'Montserrat',
//             color: Colors.white,
//             fontWeight: FontWeight.w600,
//             fontSize: 16,
//           ),
//         ),
//         backgroundColor: Constant.orangeHuflit,
//         actions: [
//           IconButton(
//             icon: Icon(
//               isFlashOn ? Icons.highlight_rounded : Icons.flashlight_off,
//               color: Colors.white,
//             ),
//             onPressed: toggleFlash,
//           ),
//           IconButton(
//             icon: const Icon(
//               Icons.flip_camera_ios,
//               color: Colors.white,
//             ),
//             onPressed: switchCamera,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(child: Center(child: CameraPreview(cameraController!))),
//           const SizedBox(height: 16),
//           Text(
//             result,
//             style: GoogleFonts.getFont(
//               'Montserrat',
//               fontWeight: FontWeight.normal,
//               fontSize: 14,
//             ),
//           ),
//           GestureDetector(
//             onTap: captureAndSendImage,
//             child: Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Container(
//                 width: MediaQuery.of(context).size.width,
//                 decoration: BoxDecoration(
//                   color: Constant.purpleHuflit,
//                   borderRadius: BorderRadius.circular(8.0),
//                   border: Border.all(color: Colors.white10, width: 2),
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(
//                       horizontal: 8.0, vertical: 6.0),
//                   child: Center(
//                     child: Text(
//                       "Chụp ảnh",
//                       textAlign: TextAlign.start,
//                       style: GoogleFonts.getFont(
//                         'Montserrat',
//                         fontWeight: FontWeight.w500,
//                         fontSize: 14,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:admin_bus_system_management/bloc/face_recognition/face_recognition_bloc.dart';
import 'package:admin_bus_system_management/bloc/face_recognition/face_recognition_state.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../bloc/face_recognition/face_recognition_event.dart';
import '../util/constant.dart';

class FaceRecognitionScreen extends StatelessWidget {
  const FaceRecognitionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<FaceRecognitionBloc, FaceRecognitionState> (
      listener: (context, state) {
        if (state is FaceRecognitionSuccess) {
          // Navigate to result screen with student_id
          context.push('/face_recognition/add_attendance',
              extra: state.studentID);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            color: Colors.white,
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onPressed: () => context.pop(),
          ),
          title: Text(
            "Quét mặt điểm danh",
            style: GoogleFonts.getFont(
              'Montserrat',
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          backgroundColor: Constant.orangeHuflit,
          actions: [
            BlocBuilder<FaceRecognitionBloc, FaceRecognitionState>(
              builder: (context, state) {
                if (state is CameraInitialized) {
                  return Row(
                    children: [
                      IconButton(
                        icon: Icon(
                          state.isFlashOn
                              ? Icons.highlight_rounded
                              : Icons.flashlight_off,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          context.read<FaceRecognitionBloc>().add(ToggleFlashEvent());
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          context.read<FaceRecognitionBloc>().add(SwitchCameraEvent());
                        },
                      ),
                    ],
                  );
                }
                return Container();
              },
            ),
          ],
        ),
        body: BlocBuilder<FaceRecognitionBloc, FaceRecognitionState>(
          builder: (context, state) {
            if (state is CameraInitialized) {
              return Column(
                children: [
                  Expanded(child: Center(child: CameraPreview(state.cameraController))),
                  const SizedBox(height: 16),
                  Text(
                    state.result,
                    style: GoogleFonts.getFont(
                      'Montserrat',
                      fontWeight: FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      context.read<FaceRecognitionBloc>().add(CaptureAndSendImageEvent());
                      print(state.result);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          color: Constant.purpleHuflit,
                          borderRadius: BorderRadius.circular(8.0),
                          border: Border.all(color: Colors.white10, width: 2),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Text(
                              "Chụp ảnh",
                              textAlign: TextAlign.start,
                              style: GoogleFonts.getFont(
                                'Montserrat',
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
