import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/stayeasy_app.dart';
import 'core/backend/supabase_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  final configured =
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
  if (configured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
    );
  }

  runApp(
    ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(
          configured ? Supabase.instance.client : null,
        ),
      ],
      child: const StayEasyApp(),
    ),
  );
}
