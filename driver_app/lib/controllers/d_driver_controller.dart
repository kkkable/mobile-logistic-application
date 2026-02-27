import 'package:flutter/material.dart';
import '../models/d_driver.dart';
import '../repositories/d_driver_repository.dart';

class DriverController extends ChangeNotifier {
  final DriverRepository _driverRepository = DriverRepository();
  Driver? _driver;

  Driver? get driver => _driver;

  Future<void> fetchDriver(int driverId, String token) async {
    try {
      _driver = await _driverRepository.fetchDriver(driverId, token);
      notifyListeners();
    } catch (e) {
      print('Error fetching driver: $e');
    }
  }
}
