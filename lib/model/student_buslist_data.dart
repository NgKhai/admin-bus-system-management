import 'package:admin_bus_system_management/model/bus_data.dart';
import 'package:admin_bus_system_management/model/student_data.dart';

class StudentBusListData {
  final StudentData studentData;
  final List<BusData> busListData;

  StudentBusListData(this.studentData, this.busListData);
}