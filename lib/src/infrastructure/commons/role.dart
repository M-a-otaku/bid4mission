


enum Role { hunter, employer }


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


String roleToString(Role r) => r == Role.employer ? 'employer' : 'hunter';

extension RoleX on Role {
  bool get isHunter => this == Role.hunter;
  bool get isEmployer => this == Role.employer;
}




