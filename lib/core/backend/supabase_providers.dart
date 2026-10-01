import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Null in widget/unit tests and when running without backend configuration.
final supabaseClientProvider = Provider<SupabaseClient?>((ref) => null);

final backendEnabledProvider = Provider<bool>(
  (ref) => ref.watch(supabaseClientProvider) != null,
);
