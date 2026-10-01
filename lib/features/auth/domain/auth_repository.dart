class StayEasyProfile {
  const StayEasyProfile({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
  });
  final String id;
  final String email;
  final String? fullName;
  final String role;
  bool get isAdmin => role == 'admin';
}

abstract interface class AuthRepository {
  Stream<StayEasyProfile?> get profileChanges;
  Future<StayEasyProfile?> currentProfile();
  Future<StayEasyProfile?> signIn(String email, String password);
  Future<StayEasyProfile?> signUp(
    String email,
    String password,
    String fullName,
  );
  Future<void> signOut();
}
