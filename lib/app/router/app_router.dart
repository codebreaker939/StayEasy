import 'package:go_router/go_router.dart';

import '../../features/explore/presentation/pages/explore_page.dart';
import '../../features/hotel_details/presentation/pages/hotel_details_page.dart';
import '../../features/room_details/presentation/pages/room_details_page.dart';
import '../../features/search/presentation/pages/search_results_page.dart';
import '../../features/booking/presentation/pages/date_selection_page.dart';
import '../../features/booking/presentation/pages/reviews_page.dart';
import '../../features/booking/presentation/pages/booking_pages.dart';
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
        GoRoute(
          path: AppRoutes.dates,
          name: AppRoutes.datesName,
          builder: (context, state) =>
              DateSelectionPage(roomId: state.pathParameters['roomId']!),
        ),
        GoRoute(
          path: AppRoutes.reviews,
          name: AppRoutes.reviewsName,
          builder: (context, state) => const ReviewsPage(),
        ),
        GoRoute(
          path: AppRoutes.bookingGuest,
          name: AppRoutes.bookingGuestName,
          builder: (context, state) => const BookingGuestPage(),
        ),
        GoRoute(
          path: AppRoutes.bookingReview,
          name: AppRoutes.bookingReviewName,
          builder: (context, state) => const BookingSummaryPage(),
        ),
        GoRoute(
          path: AppRoutes.bookingConfirmation,
          name: AppRoutes.bookingConfirmationName,
          builder: (context, state) => const BookingConfirmationPage(),
        ),
        GoRoute(
          path: AppRoutes.bookingSuccess,
          name: AppRoutes.bookingSuccessName,
          builder: (context, state) => const BookingSuccessPage(),
        ),
        GoRoute(
          path: AppRoutes.trips,
          name: AppRoutes.tripsName,
          builder: (context, state) => const MyTripsPage(),
        ),
      ],
    );

final GoRouter appRouter = createAppRouter();
