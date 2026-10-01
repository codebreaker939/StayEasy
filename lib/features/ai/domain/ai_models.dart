class AiSearchFilters {
  const AiSearchFilters({
    this.city,
    this.month,
    this.checkIn,
    this.checkOut,
    this.guests,
    this.maxPriceInr,
    this.minRating,
    this.amenities = const [],
    this.roomTypes = const [],
    this.vibes = const [],
  });

  final String? city;
  final int? month;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? guests;
  final double? maxPriceInr;
  final double? minRating;
  final List<String> amenities;
  final List<String> roomTypes;
  final List<String> vibes;

  factory AiSearchFilters.fromJson(Object? json) {
    if (json is! Map) throw const FormatException('Invalid search filters');
    final month = _intOrNull(json['month']);
    final guests = _intOrNull(json['guests']);
    final price = _doubleOrNull(json['max_price_inr']);
    final rating = _doubleOrNull(json['min_rating']);
    return AiSearchFilters(
      city: _stringOrNull(json['city']),
      month: month != null && month >= 1 && month <= 12 ? month : null,
      checkIn: _dateOrNull(json['check_in']),
      checkOut: _dateOrNull(json['check_out']),
      guests: guests != null && guests >= 1 && guests <= 8 ? guests : null,
      maxPriceInr: price != null && price >= 0 ? price : null,
      minRating: rating != null && rating >= 0 && rating <= 5 ? rating : null,
      amenities: _stringList(json['amenities']),
      roomTypes: _stringList(json['room_types']),
      vibes: _stringList(json['vibes']),
    );
  }

  AiSearchFilters copyWith({
    Object? city = _unset,
    Object? month = _unset,
    Object? checkIn = _unset,
    Object? checkOut = _unset,
    Object? guests = _unset,
    Object? maxPriceInr = _unset,
    Object? minRating = _unset,
    List<String>? amenities,
    List<String>? roomTypes,
    List<String>? vibes,
  }) => AiSearchFilters(
    city: identical(city, _unset) ? this.city : city as String?,
    month: identical(month, _unset) ? this.month : month as int?,
    checkIn: identical(checkIn, _unset) ? this.checkIn : checkIn as DateTime?,
    checkOut: identical(checkOut, _unset)
        ? this.checkOut
        : checkOut as DateTime?,
    guests: identical(guests, _unset) ? this.guests : guests as int?,
    maxPriceInr: identical(maxPriceInr, _unset)
        ? this.maxPriceInr
        : maxPriceInr as double?,
    minRating: identical(minRating, _unset)
        ? this.minRating
        : minRating as double?,
    amenities: amenities ?? this.amenities,
    roomTypes: roomTypes ?? this.roomTypes,
    vibes: vibes ?? this.vibes,
  );
}

const _unset = Object();

class AiClarification {
  const AiClarification({required this.question, required this.options});
  final String question;
  final List<String> options;
}

class AiSearchInterpretation {
  const AiSearchInterpretation({
    required this.status,
    required this.filters,
    required this.clarification,
  });

  final AiSearchStatus status;
  final AiSearchFilters filters;
  final AiClarification? clarification;

  factory AiSearchInterpretation.fromJson(Object? json) {
    if (json is! Map ||
        !['parsed', 'needs_clarification'].contains(json['status'])) {
      throw const FormatException('Invalid search interpretation');
    }
    final clarificationJson = json['clarification'];
    AiClarification? clarification;
    if (clarificationJson is Map && clarificationJson['question'] is String) {
      clarification = AiClarification(
        question: clarificationJson['question'] as String,
        options: _stringList(clarificationJson['options']),
      );
    }
    final status =
        json['status'] == 'needs_clarification' && clarification != null
        ? AiSearchStatus.needsClarification
        : AiSearchStatus.parsed;
    return AiSearchInterpretation(
      status: status,
      filters: AiSearchFilters.fromJson(json['filters']),
      clarification: clarification,
    );
  }
}

enum AiSearchStatus { parsed, needsClarification }

class ReviewAiBullet {
  const ReviewAiBullet({required this.text, required this.sourceReviewIds});
  final String text;
  final List<String> sourceReviewIds;
}

class ReviewAiInsight {
  const ReviewAiInsight({
    required this.status,
    required this.title,
    required this.bullets,
    required this.caution,
    required this.sourceCount,
  });
  final ReviewAiStatus status;
  final String title;
  final List<ReviewAiBullet> bullets;
  final ReviewAiBullet? caution;
  final int sourceCount;

  factory ReviewAiInsight.fromJson(Object? json) {
    if (json is! Map ||
        !['ready', 'insufficient_evidence'].contains(json['status'])) {
      throw const FormatException('Invalid review insight');
    }
    ReviewAiBullet parseBullet(Object? value) {
      if (value is! Map ||
          value['text'] is! String ||
          value['source_review_ids'] is! List) {
        throw const FormatException('Invalid review insight bullet');
      }
      final ids = _stringList(value['source_review_ids']);
      return ReviewAiBullet(
        text: value['text'] as String,
        sourceReviewIds: ids,
      );
    }

    final rows = json['bullets'];
    if (rows is! List) {
      throw const FormatException('Invalid review insight bullets');
    }
    final cautionJson = json['caution'];
    return ReviewAiInsight(
      status: json['status'] == 'ready'
          ? ReviewAiStatus.ready
          : ReviewAiStatus.insufficientEvidence,
      title: json['title'] is String
          ? json['title'] as String
          : 'Stay insights',
      bullets: rows.map(parseBullet).toList(growable: false),
      caution: cautionJson == null ? null : parseBullet(cautionJson),
      sourceCount: _intOrNull(json['source_count']) ?? 0,
    );
  }
}

enum ReviewAiStatus { ready, insufficientEvidence }

String? _stringOrNull(Object? value) =>
    value is String && value.trim().isNotEmpty ? value.trim() : null;
int? _intOrNull(Object? value) => value is int
    ? value
    : value is num && value.isFinite && value == value.roundToDouble()
    ? value.toInt()
    : null;
double? _doubleOrNull(Object? value) =>
    value is num && value.isFinite ? value.toDouble() : null;
DateTime? _dateOrNull(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final date = DateTime.tryParse(value);
  return date != null && date.toIso8601String().startsWith(value) ? date : null;
}

List<String> _stringList(Object? value) => value is List
    ? value
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toSet()
          .toList(growable: false)
    : const [];
