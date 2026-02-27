class Driver {
  final int driverId;
  final String name;
  final String email;
  final String phone;
  final String vehicleDetails;
  final String workingTime;
  final String username;
  final double avgRating;

  Driver({
    required this.driverId,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleDetails,
    required this.workingTime,
    required this.username,
    required this.avgRating,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      driverId: json['driver_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      vehicleDetails: json['vehicle_details'],
      workingTime: json['working_time'] ?? '',
      username: json['username'],
      avgRating: double.parse(json['avg_rating'].toString()),
    );
  }
}