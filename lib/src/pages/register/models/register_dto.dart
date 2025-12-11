class RegisterDto {
  final String username;
  final String firstname;
  final String lastname;
  final String password;
  final String role;

  RegisterDto({
    required this.username,
    required this.firstname,
    required this.lastname,
    required this.password,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'firstname': firstname,
        'lastname': lastname,
        'password': password,
        'role': role,
      };
}


