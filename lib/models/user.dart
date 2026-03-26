class User {
  final int id;
  final String name;
  final String email;
  final String? token;
  final String? role;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.token,
    this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'] ?? json['nom'] ?? '',
      email: json['email'] ?? '',
      token: json['token'],
      role: json['role'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'token': token,
      'role': role,
    };
  }
}
