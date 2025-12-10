// ...existing code...

/// Role enum used across the app instead of raw strings.
enum Role { hunter, employer }

/// Parse a role from a stored string (e.g. from local storage).
Role parseRole(String? s) {
  if (s == null) return Role.hunter;
  switch (s.toLowerCase()) {
    case 'employer':
      return Role.employer;
    case 'hunter':
    default:
      return Role.hunter;
  }
}

/// Convert enum to the string value expected by the server/local storage.
String roleToString(Role r) => r == Role.employer ? 'employer' : 'hunter';

extension RoleX on Role {
  bool get isHunter => this == Role.hunter;
  bool get isEmployer => this == Role.employer;
}

// ...existing code...
