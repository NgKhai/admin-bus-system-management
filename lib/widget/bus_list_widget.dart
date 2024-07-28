import 'package:admin_bus_system_management/model/bus_data.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../util/hex_color.dart';

class BusListWidget extends StatelessWidget {
  final BusData busData;
  final void Function() onTap;

  const BusListWidget({
    super.key,
    required this.busData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0),
        padding: const EdgeInsets.all(15.0),
        decoration: BoxDecoration(
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: HexColor(busData.busEndColor).withOpacity(0.6),
              offset: const Offset(1.1, 4.0),
              blurRadius: 8.0,
            ),
          ],
          gradient: LinearGradient(
            colors: <HexColor>[
              HexColor(busData.busStartColor),
              HexColor(busData.busEndColor),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Center(
                child: Image.network(busData.busImage, fit: BoxFit.contain, errorBuilder: (BuildContext context, Object exception, StackTrace? stackTrace) {
                  return Image.asset('assets/images/bus.png', fit: BoxFit.contain,);
                },),
              ),
            ),
            const SizedBox(height: 10), // Add some spacing between image and text
            Text(
              busData.busName,
              style: GoogleFonts.getFont(
                'Montserrat',
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              busData.busLicense,
              style: GoogleFonts.getFont(
                'Montserrat',
                fontSize: 12.0,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
