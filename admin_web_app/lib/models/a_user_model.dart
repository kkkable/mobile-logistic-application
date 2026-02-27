class User {
  final int userId;
  String name;
  String email;
  String phone;
  String address;
  String username;

  User({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      username: json['username'],
    );
  }
}
