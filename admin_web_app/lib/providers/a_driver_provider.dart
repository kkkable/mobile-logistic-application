import 'package:flutter/material.dart';
import '../repositories/a_driver_repository.dart';
import '../models/a_driver_model.dart';
import '../models/a_rating_model.dart';

class DriverProvider with ChangeNotifier {
  final DriverRepository _driverRepository = DriverRepository();
  List<Driver> _drivers = [];
  List<Rating> _ratings = [];

  List<Driver> get drivers => _drivers;
  List<Rating> get ratings => _ratings;

  Future<void> fetchDrivers(String token) async {
    try {
      _drivers = await _driverRepository.getDrivers(token);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  Future<void> fetchRatings(String token) async {
    try {
      _ratings = await _driverRepository.getAllRatings(token);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }

  List<Rating> getRatingsForDriver(int driverId) {
    return _ratings.where((r) => r.driverId == driverId).toList();
  }

  Rating? getLatestRatingForDriver(int driverId) {
    final list = getRatingsForDriver(driverId);
    if (list.isEmpty) return null;
    list.sort((a, b) => b.ratingId.compareTo(a.ratingId));
    return list.first;
  }
}