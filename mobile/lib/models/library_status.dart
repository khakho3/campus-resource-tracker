class SeatStatus {
  const SeatStatus({
    required this.id,
    required this.code,
    required this.isOccupied,
    required this.lastDistanceCm,
    required this.updatedAt,
  });

  final int id;
  final String code;
  final bool isOccupied;
  final double? lastDistanceCm;
  final DateTime updatedAt;

  factory SeatStatus.fromJson(Map<String, dynamic> json) {
    return SeatStatus(
      id: json['id'] as int,
      code: json['code'] as String,
      isOccupied: json['is_occupied'] as bool,
      lastDistanceCm: (json['last_distance_cm'] as num?)?.toDouble(),
      updatedAt: parseApiDate(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'is_occupied': isOccupied,
    'last_distance_cm': lastDistanceCm,
    'updated_at': updatedAt.toUtc().toIso8601String(),
  };
}

class LibraryStatus {
  const LibraryStatus({
    required this.libraryId,
    required this.libraryName,
    required this.isOpen,
    required this.openingTime,
    required this.closingTime,
    required this.motionDetected,
    required this.totalSeats,
    required this.occupiedSeats,
    required this.availableSeats,
    required this.occupancyPercentage,
    required this.isFull,
    required this.status,
    required this.staffPresent,
    required this.seats,
    required this.lastUpdateTime,
  });

  final int libraryId;
  final String libraryName;
  final bool isOpen;
  final String openingTime;
  final String closingTime;
  final bool motionDetected;
  final int totalSeats;
  final int occupiedSeats;
  final int availableSeats;
  final double occupancyPercentage;
  final bool isFull;
  final String status;
  final bool staffPresent;
  final List<SeatStatus> seats;
  final DateTime lastUpdateTime;

  factory LibraryStatus.fromJson(Map<String, dynamic> json) {
    return LibraryStatus(
      libraryId: json['library_id'] as int,
      libraryName: json['library_name'] as String,
      isOpen: json['is_open'] as bool,
      openingTime: json['opening_time'] as String,
      closingTime: json['closing_time'] as String,
      motionDetected: json['motion_detected'] as bool,
      totalSeats: json['total_seats'] as int,
      occupiedSeats: json['occupied_seats'] as int,
      availableSeats: json['available_seats'] as int,
      occupancyPercentage: (json['occupancy_percentage'] as num).toDouble(),
      isFull: json['is_full'] as bool,
      status: json['status'] as String,
      staffPresent: json['staff_present'] as bool,
      seats: (json['seats'] as List<dynamic>)
          .map((seat) => SeatStatus.fromJson(seat as Map<String, dynamic>))
          .toList(growable: false),
      lastUpdateTime: parseApiDate(json['last_update_time'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'library_id': libraryId,
    'library_name': libraryName,
    'is_open': isOpen,
    'opening_time': openingTime,
    'closing_time': closingTime,
    'motion_detected': motionDetected,
    'total_seats': totalSeats,
    'occupied_seats': occupiedSeats,
    'available_seats': availableSeats,
    'occupancy_percentage': occupancyPercentage,
    'is_full': isFull,
    'status': status,
    'staff_present': staffPresent,
    'seats': seats.map((seat) => seat.toJson()).toList(growable: false),
    'last_update_time': lastUpdateTime.toUtc().toIso8601String(),
  };
}

DateTime parseApiDate(String value) {
  final parsed = DateTime.parse(value);
  if (parsed.isUtc) {
    return parsed;
  }
  return DateTime.utc(
    parsed.year,
    parsed.month,
    parsed.day,
    parsed.hour,
    parsed.minute,
    parsed.second,
    parsed.millisecond,
    parsed.microsecond,
  );
}
