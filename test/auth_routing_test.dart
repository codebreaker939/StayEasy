import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stayeasy/app/router/app_router.dart';
import 'package:stayeasy/app/router/app_routes.dart';
import 'package:stayeasy/app/stayeasy_app.dart';
import 'package:stayeasy/core/backend/supabase_providers.dart';
import 'package:stayeasy/features/auth/domain/auth_repository.dart';
import 'package:stayeasy/features/booking/application/booking_provider.dart';
import 'package:stayeasy/features/admin/data/admin_repository.dart';

Widget _app(String path) => ProviderScope(
  child: StayEasyApp(router: createAppRouter(initialLocation: path)),
);

void main() {
  testWidgets(
    'guest can browse and unauthenticated booking confirmation redirects to sign in',
    (tester) async {
      await tester.pumpWidget(_app(AppRoutes.explore));
      await tester.pumpAndSettle();
      expect(find.text('Where are you\nstaying next?'), findsOneWidget);

      await tester.pumpWidget(
        ProviderScope(
          key: UniqueKey(),
          overrides: [
            backendEnabledProvider.overrideWithValue(true),
            authProfileProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: StayEasyApp(
            router: createAppRouter(
              initialLocation: AppRoutes.bookingConfirmation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Continue as guest'), findsOneWidget);
    },
  );

  testWidgets('admin route rejects a normal user profile', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProfileProvider.overrideWith(
            (ref) => Stream.value(
              const StayEasyProfile(
                id: 'user-1',
                email: 'guest@example.test',
                role: 'user',
              ),
            ),
          ),
        ],
        child: StayEasyApp(
          router: createAppRouter(initialLocation: AppRoutes.admin),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Overview'), findsNothing);
  });

  testWidgets('admin route opens for backend profile role admin', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProfileProvider.overrideWith(
            (ref) => Stream.value(
              const StayEasyProfile(
                id: 'admin-1',
                email: 'admin@example.test',
                role: 'admin',
              ),
            ),
          ),
        ],
        child: StayEasyApp(
          router: createAppRouter(initialLocation: AppRoutes.admin),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('StayEasy Admin'), findsOneWidget);
    expect(
      find.text('Connect StayEasy to Supabase to open the admin workspace.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'admin pages remain usable at compact, medium and expanded widths',
    (tester) async {
      for (final width in [390.0, 834.0, 1440.0]) {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        for (final (route, title) in [
          (AppRoutes.admin, 'Dashboard'),
          (AppRoutes.adminHotels, 'Hotels'),
          (AppRoutes.adminRooms, 'Rooms'),
          (AppRoutes.adminAvailability, 'Availability'),
          (AppRoutes.adminBookings, 'Bookings'),
          (AppRoutes.adminReviews, 'Reviews'),
        ]) {
          await tester.pumpWidget(
            ProviderScope(
              key: UniqueKey(),
              overrides: [
                adminRepositoryProvider.overrideWithValue(null),
                authProfileProvider.overrideWith(
                  (ref) => Stream.value(
                    const StayEasyProfile(
                      id: 'admin-1',
                      email: 'admin@example.test',
                      role: 'admin',
                    ),
                  ),
                ),
              ],
              child: StayEasyApp(
                router: createAppRouter(initialLocation: route),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.text(title), findsWidgets);
          expect(tester.takeException(), isNull, reason: '$route at $width px');
        }
      }
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    },
  );
}
