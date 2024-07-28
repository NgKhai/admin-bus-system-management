import 'package:admin_bus_system_management/bloc/face_recognition/face_recognition_bloc.dart';
import 'package:admin_bus_system_management/screen/face_recognition_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'face_recognition_event.dart';

class FaceRecognitionProvider extends StatelessWidget {

  const FaceRecognitionProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => FaceRecognitionBloc()..add(InitializeCameraEvent()),
      child: const FaceRecognitionScreen(),
    );
  }
}