class AppUser {
  final String? profilePicture;
  final String name;
  final String phone;
  final String gender;
  final String dateOfBirth;

  AppUser({
    this.profilePicture,
    required this.name,
    required this.phone,
    required this.gender,
    required this.dateOfBirth,
  });

  // Factory method to map data from Firestore to AppUser object
  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      profilePicture: map['profilePicture'] as String?,
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      gender: map['gender'] ?? 'Male',
      dateOfBirth: map['dateOfBirth'] ?? '',
    );
  }
}
