class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String password;
  final String? imagePath;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'imagePath': imagePath,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      name: map['name'],
      email: map['email'],
      phone: map['phone'],
      password: map['password'],
      imagePath: map['imagePath'],
    );
  }
}
