enum UserRole { citizen, admin }

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final int gamificationPoints;
  final List<String> badges;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.gamificationPoints = 0,
    this.badges = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role.name,
        'gamificationPoints': gamificationPoints,
        'badges': badges,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        phone: json['phone'],
        role: UserRole.values.firstWhere((e) => e.name == json['role']),
        gamificationPoints: json['gamificationPoints'] ?? 0,
        badges: List<String>.from(json['badges'] ?? []),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
      );

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    UserRole? role,
    int? gamificationPoints,
    List<String>? badges,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      UserModel(
        id: id ?? this.id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role ?? this.role,
        gamificationPoints: gamificationPoints ?? this.gamificationPoints,
        badges: badges ?? this.badges,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
