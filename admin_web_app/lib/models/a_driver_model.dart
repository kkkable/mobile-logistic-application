class Driver {
  final int driverId;
  String name;
  String email;
  String phone;
  String vehicleDetails;
  String username;
  final double avgRating;
  final double maxWeight;
  final String? workingTime;
  final List<String> expectedRoute;

  Driver({
    required this.driverId,
    required this.name,
    required this.email,
    required this.phone,
    required this.vehicleDetails,
    required this.username,
    required this.avgRating,
    this.maxWeight = 50.0,
    this.workingTime,
    this.expectedRoute = const [],
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      driverId: json['driver_id'] ?? json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      vehicleDetails: json['vehicle_details'] ?? '',
      username: json['username'] ?? '',
      avgRating: double.tryParse(json['avg_rating'].toString()) ?? 0.0,
      maxWeight: double.tryParse(json['max_weight'].toString()) ?? 50.0,
      workingTime: json['working_time'],
      expectedRoute: (json['expected_route'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ?? 
          [],
    );
  }
}