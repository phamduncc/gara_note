class User {
  final int? id;
  final String username;
  final String password;
  final String role;
  final String fullName;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.fullName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'role': role,
      'full_name': fullName,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      role: map['role'],
      fullName: map['full_name'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  bool get isOwner => role == 'owner';
  bool get isEmployee => role == 'employee';
}
