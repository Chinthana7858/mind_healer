class Psychiatrist {
  final String id;
  final String name;
  final String qualification;
  final String profilePicture;
  final String email;
  final String? specialty;
  final Map<String, String> availabilityStartTimes;
  final Map<String, String> availabilityEndTimes;

  Psychiatrist({
    required this.id,
    required this.name,
    required this.qualification,
    required this.profilePicture,
    required this.email,
    this.specialty,
    required this.availabilityStartTimes,
    required this.availabilityEndTimes,
  });

  // Factory method to create an instance of Psychiatrist from Firestore data
  factory Psychiatrist.fromMap(String id, Map<String, dynamic> map) {
    return Psychiatrist(
      id: id,
      name: map['name'] ?? '',
      qualification: map['qualification'] ?? '',
      profilePicture: map['profilePicture'] ?? '',
      email: map['email'] ?? '',
      specialty: map['speciality'],
      availabilityStartTimes: Map<String, String>.from(map['availability']['startTimes'] ?? {}),
      availabilityEndTimes: Map<String, String>.from(map['availability']['endTimes'] ?? {}),
    );
  }
}
