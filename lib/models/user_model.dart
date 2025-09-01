class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      uid: data['uid'] ?? '',
      firstName: data['first_name'] ?? '',
      lastName: data['last_name'] ?? '',
      email: data['email'] ?? '',
      phoneNumber: data['phone_number'] ?? '',
    );
  }

  // Convert UserModel to a Map (for Firestore)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone_number': phoneNumber,
    };
  }
}