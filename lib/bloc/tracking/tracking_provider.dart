import 'package:admin_bus_system_management/model/bus_data.dart';
import 'package:admin_bus_system_management/util/hex_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../screen/add_tracking.dart';
import '../../util/constant.dart';
import 'tracking_bloc.dart';

class TrackingProvider extends StatelessWidget {

  final BusData busData;

  const TrackingProvider({super.key, required this.busData});

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
          busData.busName,
          style: GoogleFonts.getFont(
            'Montserrat',
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),

        backgroundColor: Constant.orangeHuflit,
      ),
      body: BlocProvider(
        create: (context) => TrackingBloc(busData),
        child: AddTracking(busData: busData),
      ),
    );
  }
}