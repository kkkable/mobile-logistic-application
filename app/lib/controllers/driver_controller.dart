import 'package:flutter/material.dart';
import '../repositories/driver_repository.dart';
import '../models/driver.dart';

class DriverController extends ChangeNotifier {
  final DriverRepository _repository = DriverRepository();
  Map<int, Driver> drivers = {};

  Future<void> fetchDriverDetails(int driverId, String token) async {
    try {
      final response = await _repository.fetchDriverDetails(driverId, token);
      drivers[driverId] = response;
      notifyListeners();
    } catch (e) {
      drivers[driverId] = Driver(driverId: driverId, name: 'Unknown Driver', avgRating: 0.0);
      notifyListeners();
    }
  }

  Future<void> fetchDriverAverageRating(int driverId, String token) async {
    try {
      final rating = await _repository.fetchDriverAverageRating(driverId, token);
      if (drivers.containsKey(driverId)) {
        drivers[driverId]!.avgRating = rating;
      } else {
        drivers[driverId] = Driver(driverId: driverId, name: 'Unknown Driver', avgRating: rating);
      }
      notifyListeners();
    } catch (e) {
      if (!drivers.containsKey(driverId)) {
        drivers[driverId] = Driver(driverId: driverId, name: 'Unknown Driver', avgRating: 0.0);
      }
      notifyListeners();
    }
  }
}