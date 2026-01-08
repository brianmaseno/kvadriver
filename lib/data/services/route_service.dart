// lib/data/services/route_service.dart
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'api_service.dart';

/// Service to handle route calculations and navigation
class RouteService extends ChangeNotifier {
  List<LatLng> _routePoints = [];
  double _totalDistanceKm = 0;
  double _estimatedDurationMinutes = 0;
  List<RouteStep> _steps = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<LatLng> get routePoints => _routePoints;
  double get totalDistanceKm => _totalDistanceKm;
  double get estimatedDurationMinutes => _estimatedDurationMinutes;
  List<RouteStep> get steps => _steps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Calculate and load route between two points
  Future<bool> calculateRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.getRoute(
        startLat: startLat,
        startLng: startLng,
        endLat: endLat,
        endLng: endLng,
      );

      if (response['code'] == 'Ok' && response['routes'] != null) {
        final routes = response['routes'] as List;
        if (routes.isNotEmpty) {
          final route = routes[0];
          
          // Parse geometry (GeoJSON coordinates)
          final geometry = route['geometry'];
          if (geometry != null && geometry['coordinates'] != null) {
            final coordinates = geometry['coordinates'] as List;
            _routePoints = coordinates.map<LatLng>((coord) {
              return LatLng(coord[1].toDouble(), coord[0].toDouble());
            }).toList();
          }

          // Parse distance and duration
          _totalDistanceKm = (route['distance'] ?? 0) / 1000; // Convert meters to km
          _estimatedDurationMinutes = (route['duration'] ?? 0) / 60; // Convert seconds to minutes

          // Parse steps for turn-by-turn navigation
          _steps = [];
          final legs = route['legs'] as List?;
          if (legs != null && legs.isNotEmpty) {
            for (final leg in legs) {
              final legSteps = leg['steps'] as List?;
              if (legSteps != null) {
                for (final step in legSteps) {
                  _steps.add(RouteStep.fromJson(step));
                }
              }
            }
          }

          _isLoading = false;
          notifyListeners();
          return true;
        }
      }

      _error = 'No route found';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'Failed to calculate route: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Clear current route
  void clearRoute() {
    _routePoints = [];
    _totalDistanceKm = 0;
    _estimatedDurationMinutes = 0;
    _steps = [];
    _error = null;
    notifyListeners();
  }

  /// Get the current step based on driver's location
  RouteStep? getCurrentStep(LatLng currentLocation) {
    if (_steps.isEmpty) return null;

    // Find the closest step to the driver's current location
    RouteStep? closestStep;
    double minDistance = double.infinity;

    for (final step in _steps) {
      if (step.location != null) {
        final distance = const Distance().as(
          LengthUnit.Meter,
          currentLocation,
          step.location!,
        );
        if (distance < minDistance) {
          minDistance = distance;
          closestStep = step;
        }
      }
    }

    return closestStep;
  }

  /// Get formatted duration string
  String get formattedDuration {
    final hours = _estimatedDurationMinutes ~/ 60;
    final minutes = _estimatedDurationMinutes.round() % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes} min';
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (_totalDistanceKm < 1) {
      return '${(_totalDistanceKm * 1000).round()} m';
    }
    return '${_totalDistanceKm.toStringAsFixed(1)} km';
  }
}

/// Represents a step in the route (turn-by-turn navigation)
class RouteStep {
  final String? instruction;
  final String? name;
  final String? maneuver;
  final double? distance;
  final double? duration;
  final LatLng? location;

  RouteStep({
    this.instruction,
    this.name,
    this.maneuver,
    this.distance,
    this.duration,
    this.location,
  });

  factory RouteStep.fromJson(Map<String, dynamic> json) {
    LatLng? location;
    final maneuverData = json['maneuver'];
    if (maneuverData != null && maneuverData['location'] != null) {
      final loc = maneuverData['location'] as List;
      location = LatLng(loc[1].toDouble(), loc[0].toDouble());
    }

    return RouteStep(
      instruction: maneuverData?['instruction'] ?? _buildInstruction(json),
      name: json['name'],
      maneuver: maneuverData?['type'],
      distance: (json['distance'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toDouble(),
      location: location,
    );
  }

  static String _buildInstruction(Map<String, dynamic> json) {
    final maneuver = json['maneuver'];
    if (maneuver == null) return 'Continue';

    final type = maneuver['type'] ?? '';
    final modifier = maneuver['modifier'] ?? '';
    final name = json['name'] ?? 'the road';

    switch (type) {
      case 'turn':
        return 'Turn $modifier onto $name';
      case 'new name':
        return 'Continue onto $name';
      case 'merge':
        return 'Merge $modifier onto $name';
      case 'on ramp':
        return 'Take the ramp $modifier';
      case 'off ramp':
        return 'Take the exit $modifier';
      case 'fork':
        return 'Keep $modifier at the fork';
      case 'end of road':
        return 'At the end of the road, turn $modifier';
      case 'continue':
        return 'Continue on $name';
      case 'roundabout':
        return 'Enter the roundabout and take exit';
      case 'rotary':
        return 'Enter the rotary and take exit';
      case 'roundabout turn':
        return 'At the roundabout, turn $modifier';
      case 'notification':
        return name;
      case 'arrive':
        return 'You have arrived at your destination';
      case 'depart':
        return 'Head $modifier on $name';
      default:
        return 'Continue on $name';
    }
  }

  /// Get icon for this step's maneuver
  IconData get icon {
    switch (maneuver) {
      case 'turn':
        if (instruction?.contains('left') ?? false) return Icons.turn_left;
        if (instruction?.contains('right') ?? false) return Icons.turn_right;
        return Icons.straight;
      case 'merge':
        return Icons.merge_type;
      case 'on ramp':
      case 'off ramp':
        return Icons.exit_to_app;
      case 'fork':
        return Icons.call_split;
      case 'roundabout':
      case 'rotary':
        return Icons.rotate_right;
      case 'arrive':
        return Icons.location_on;
      case 'depart':
        return Icons.trip_origin;
      default:
        return Icons.arrow_upward;
    }
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distance == null) return '';
    if (distance! < 1000) {
      return '${distance!.round()} m';
    }
    return '${(distance! / 1000).toStringAsFixed(1)} km';
  }
}
