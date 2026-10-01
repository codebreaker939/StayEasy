abstract final class AppRoutes {
  static const explore = '/';
  static const exploreName = 'explore';
  static const search = '/search';
  static const searchName = 'search';
  static const hotel = '/hotel/:hotelId';
  static const hotelName = 'hotel-details';
  static const room = '/room/:roomId';
  static const roomName = 'room-details';
  static const dates = '/room/:roomId/dates';
  static const datesName = 'date-selection';
  static const reviews = '/reviews';
  static const reviewsName = 'reviews';
  static const bookingGuest = '/booking/guest';
  static const bookingGuestName = 'booking-guest';
  static const bookingReview = '/booking/review';
  static const bookingReviewName = 'booking-review';
  static const bookingConfirmation = '/booking/confirmation';
  static const bookingConfirmationName = 'booking-confirmation';
  static const bookingSuccess = '/booking/success';
  static const bookingSuccessName = 'booking-success';
  static const trips = '/trips';
  static const tripsName = 'trips';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';
  static const admin = '/admin';
  static const adminHotels = '/admin/hotels';
  static const adminRooms = '/admin/rooms';
  static const adminAvailability = '/admin/availability';
  static const adminBookings = '/admin/bookings';
  static const adminReviews = '/admin/reviews';

  static String hotelPath(String id) => '/hotel/$id';
  static String roomPath(String id) => '/room/$id';
  static String datesPath(String id) => '/room/$id/dates';
}
