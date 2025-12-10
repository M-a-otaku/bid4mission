
import '../../../infrastructure/commons/role.dart';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final String role;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'],
    firstName: json['firstName'],
    lastName: json['lastName'],
    username: json['username'],
    password: json['password'],
    role: json['role'] ?? roleToString(Role.hunter),
  );
}