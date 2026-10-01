import 'package:go_router/go_router.dart';

import '../../features/explore/presentation/pages/explore_page.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.explore,
  routes: [
    GoRoute(
      path: AppRoutes.explore,
      name: AppRoutes.exploreName,
      builder: (context, state) => const ExplorePage(),
    ),
  ],
);
