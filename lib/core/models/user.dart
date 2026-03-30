class User {
  final String id;
  final String phoneNumber;
  final String fullName;
  final String businessName;
  final String password; // In a real app, this should be hashed

  User({
    required this.id,
    required this.phoneNumber,
    required this.fullName,
    required this.businessName,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'fullName': fullName,
      'businessName': businessName,
      'password': password,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      phoneNumber: map['phoneNumber'],
      fullName: map['fullName'],
      businessName: map['businessName'],
      password: map['password'],
    );
  }
}
