import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this.client);
  final SupabaseClient client;

  @override
  Stream<StayEasyProfile?> get profileChanges =>
      client.auth.onAuthStateChange.asyncMap((_) => currentProfile());

  @override
  Future<StayEasyProfile?> currentProfile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();
    if (row == null) return null;
    return StayEasyProfile(
      id: user.id,
      email: row['email'] as String? ?? user.email ?? '',
      fullName: row['full_name'] as String?,
      role: row['role'] as String? ?? 'user',
    );
  }

  @override
  Future<StayEasyProfile?> signIn(String email, String password) async {
    await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    return currentProfile();
  }

  @override
  Future<StayEasyProfile?> signUp(
    String email,
    String password,
    String fullName,
  ) async {
    await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
    );
    return currentProfile();
  }

  @override
  Future<void> signOut() => client.auth.signOut();
}

class GuestAuthRepository implements AuthRepository {
  @override
  Stream<StayEasyProfile?> get profileChanges => const Stream.empty();
  @override
  Future<StayEasyProfile?> currentProfile() async => null;
  @override
  Future<StayEasyProfile?> signIn(String email, String password) async => null;
  @override
  Future<StayEasyProfile?> signUp(
    String email,
    String password,
    String fullName,
  ) async => null;
  @override
  Future<void> signOut() async {}
}
