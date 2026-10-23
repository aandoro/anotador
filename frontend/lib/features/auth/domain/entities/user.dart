class User {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role; // 'admin' | 'trainer'
  final String? profileImageUrl;

  const User({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.profileImageUrl,
  });

  String get fullName => '$firstName $lastName'.trim();
  bool get isAdmin => role == 'admin';
}