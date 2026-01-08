class User {
  final int id;
  final String role;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;

  User({
    required this.id,
    required this.role,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      role: json['role'] ?? 'driver',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}

class Driver {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String city;
  final Vehicle? vehicle;
  final bool isVerified;

  Driver({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.city,
    this.vehicle,
    this.isVerified = false,
  });
}

class Vehicle {
  final String type;
  final String color;
  final String plateNumber;
  final int seats;
  final int doors;

  Vehicle({
    required this.type,
    required this.color,
    required this.plateNumber,
    required this.seats,
    required this.doors,
  });
}

class Ride {
  final String id;
  final String? riderId;
  final User? rider;
  final String? driverId;
  final String? pickupAddress;
  final String? dropoffAddress;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final String status;
  final double? fare;
  final double? estimatedDuration;
  final double? distance;
  final String? paymentMethod;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? notes;
  final double? finalFare;
  final double? odometerReading;

  Ride({
    required this.id,
    this.riderId,
    this.rider,
    this.driverId,
    this.pickupAddress,
    this.dropoffAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    required this.status,
    this.fare,
    this.estimatedDuration,
    this.distance,
    this.paymentMethod,
    this.createdAt,
    this.updatedAt,
    this.notes,
    this.finalFare,
    this.odometerReading,
  });

  factory Ride.fromJson(Map<String, dynamic> json) {
    return Ride(
      id: json['id']?.toString() ?? '',
      riderId: json['riderId']?.toString(),
      rider: json['rider'] != null ? User.fromJson(json['rider']) : null,
      driverId: json['driverId']?.toString(),
      pickupAddress: json['pickupAddress']?.toString(),
      dropoffAddress: json['dropoffAddress']?.toString(),
      pickupLat: json['pickupLat'] != null ? (json['pickupLat'] as num).toDouble() : null,
      pickupLng: json['pickupLng'] != null ? (json['pickupLng'] as num).toDouble() : null,
      dropoffLat: json['dropoffLat'] != null ? (json['dropoffLat'] as num).toDouble() : null,
      dropoffLng: json['dropoffLng'] != null ? (json['dropoffLng'] as num).toDouble() : null,
      status: json['status']?.toString() ?? 'unknown',
      fare: json['estimatedFare'] != null ? (json['estimatedFare'] as num).toDouble() : null,
      estimatedDuration: json['estimatedDuration'] != null ? (json['estimatedDuration'] as num).toDouble() : null,
      distance: json['distance'] != null ? double.tryParse(json['distance'].toString()) : null,
      paymentMethod: json['paymentMethod']?.toString(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      notes: json['notes']?.toString(),
      finalFare: json['finalFare'] != null ? (json['finalFare'] as num).toDouble() : null,
      odometerReading: json['odometerReading'] != null ? (json['odometerReading'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'riderId': riderId,
      'rider': rider?.toJson(),
      'driverId': driverId,
      'pickupAddress': pickupAddress,
      'dropoffAddress': dropoffAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'status': status,
      'fare': fare,
      'estimatedDuration': estimatedDuration,
      'distance': distance,
      'paymentMethod': paymentMethod,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'notes': notes,
      'finalFare': finalFare,
      'odometerReading': odometerReading,
    };
  }

  Ride copyWith({
    String? id,
    String? riderId,
    User? rider,
    String? driverId,
    String? pickupAddress,
    String? dropoffAddress,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    String? status,
    double? fare,
    double? estimatedDuration,
    double? distance,
    String? paymentMethod,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
    double? finalFare,
    double? odometerReading,
  }) {
    return Ride(
      id: id ?? this.id,
      riderId: riderId ?? this.riderId,
      rider: rider ?? this.rider,
      driverId: driverId ?? this.driverId,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      status: status ?? this.status,
      fare: fare ?? this.fare,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      distance: distance ?? this.distance,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      notes: notes ?? this.notes,
      finalFare: finalFare ?? this.finalFare,
      odometerReading: odometerReading ?? this.odometerReading,
    );
  }
}

class Location {
  final int? id;
  final int userId;
  final String userType; // 'driver' | 'rider'
  final double latitude;
  final double longitude;
  final double? heading;
  final double? speed;
  final int? rideId;
  final int? accuracy;
  final bool isActive;
  final bool isLiveTracking;
  final DateTime? lastLiveUpdate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Location({
    this.id,
    required this.userId,
    required this.userType,
    required this.latitude,
    required this.longitude,
    this.heading,
    this.speed,
    this.rideId,
    this.accuracy,
    required this.isActive,
    required this.isLiveTracking,
    this.lastLiveUpdate,
    this.createdAt,
    this.updatedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: json['id'] != null ? int.parse(json['id'].toString()) : null,
      userId: int.parse(json['userId'].toString()),
      userType: json['userType']?.toString() ?? 'driver',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      heading: json['heading'] != null ? double.parse(json['heading'].toString()) : null,
      speed: json['speed'] != null ? double.parse(json['speed'].toString()) : null,
      rideId: json['rideId'] != null ? int.parse(json['rideId'].toString()) : null,
      accuracy: json['accuracy'] != null ? int.parse(json['accuracy'].toString()) : null,
      isActive: json['isActive'] ?? true,
      isLiveTracking: json['isLiveTracking'] ?? false,
      lastLiveUpdate: json['lastLiveUpdate'] != null ? DateTime.parse(json['lastLiveUpdate']) : null,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userType': userType,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'speed': speed,
      'rideId': rideId,
      'accuracy': accuracy,
      'isActive': isActive,
      'isLiveTracking': isLiveTracking,
      'lastLiveUpdate': lastLiveUpdate?.toIso8601String(),
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Convert to GeoJSON format for maps
  Map<String, dynamic> toGeoJSON() {
    return {
      'type': 'Feature',
      'geometry': {
        'type': 'Point',
        'coordinates': [longitude, latitude],
      },
      'properties': {
        'userId': userId,
        'userType': userType,
        'heading': heading,
        'speed': speed,
        'accuracy': accuracy,
        'timestamp': createdAt,
        'rideId': rideId,
        'isLiveTracking': isLiveTracking,
      },
    };
  }

  Location copyWith({
    int? id,
    int? userId,
    String? userType,
    double? latitude,
    double? longitude,
    double? heading,
    double? speed,
    int? rideId,
    int? accuracy,
    bool? isActive,
    bool? isLiveTracking,
    DateTime? lastLiveUpdate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      rideId: rideId ?? this.rideId,
      accuracy: accuracy ?? this.accuracy,
      isActive: isActive ?? this.isActive,
      isLiveTracking: isLiveTracking ?? this.isLiveTracking,
      lastLiveUpdate: lastLiveUpdate ?? this.lastLiveUpdate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class NearbyUser {
  final int userId;
  final String userType;
  final double latitude;
  final double longitude;
  final int? accuracy;
  final double? heading;
  final double? speed;
  final int distance; // in meters
  final DateTime timestamp;

  NearbyUser({
    required this.userId,
    required this.userType,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    required this.distance,
    required this.timestamp,
  });

  factory NearbyUser.fromJson(Map<String, dynamic> json) {
    return NearbyUser(
      userId: int.parse(json['userId'].toString()),
      userType: json['userType']?.toString() ?? 'driver',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      accuracy: json['accuracy'] != null ? int.parse(json['accuracy'].toString()) : null,
      heading: json['heading'] != null ? double.parse(json['heading'].toString()) : null,
      speed: json['speed'] != null ? double.parse(json['speed'].toString()) : null,
      distance: int.parse(json['distance'].toString()),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userType': userType,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'distance': distance,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class ETAResult {
  final double distance; // in km
  final int duration; // in seconds
  final int durationWithTraffic; // in seconds
  final String trafficCondition;
  final List<Map<String, dynamic>>? route; // optional route data

  ETAResult({
    required this.distance,
    required this.duration,
    required this.durationWithTraffic,
    required this.trafficCondition,
    this.route,
  });

  factory ETAResult.fromJson(Map<String, dynamic> json) {
    return ETAResult(
      distance: double.parse(json['distance'].toString()),
      duration: int.parse(json['duration'].toString()),
      durationWithTraffic: int.parse(json['durationWithTraffic'].toString()),
      trafficCondition: json['trafficCondition']?.toString() ?? 'unknown',
      route: json['route'] != null ? List<Map<String, dynamic>>.from(json['route']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'distance': distance,
      'duration': duration,
      'durationWithTraffic': durationWithTraffic,
      'trafficCondition': trafficCondition,
      'route': route,
    };
  }
}