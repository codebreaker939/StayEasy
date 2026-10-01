import 'package:go_router/go_router.dart';

import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/hotel_details/presentation/pages/hotel_details_page.dart';
import '../../features/room_details/presentation/pages/room_details_page.dart';
import '../../features/search/presentation/pages/search_results_page.dart';
import 'app_routes.dart';

GoRouter createAppRouter({String initialLocation = AppRoutes.explore}) =>
    GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.explore,
          name: AppRoutes.exploreName,
          builder: (context, state) => const ExplorePage(),
        ),
        GoRoute(
          path: AppRoutes.search,
          name: AppRoutes.searchName,
          builder: (context, state) => const SearchResultsPage(),
        ),
        GoRoute(
          path: AppRoutes.hotel,
          name: AppRoutes.hotelName,
          builder: (context, state) =>
              HotelDetailsPage(hotelId: state.pathParameters['hotelId']!),
        ),
        GoRoute(
          path: AppRoutes.room,
          name: AppRoutes.roomName,
          builder: (context, state) =>
              RoomDetailsPage(roomId: state.pathParameters['roomId']!),
        ),
      ],
    );

final GoRouter appRouter = createAppRouter();
