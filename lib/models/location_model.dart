class LocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final String? landmark;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    this.landmark,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'landmark': landmark,
      };

  factory LocationModel.fromJson(Map<String, dynamic> json) => LocationModel(
        latitude: json['latitude'],
        longitude: json['longitude'],
        address: json['address'],
        landmark: json['landmark'],
      );

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? landmark,
  }) =>
      LocationModel(
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        address: address ?? this.address,
        landmark: landmark ?? this.landmark,
      );

  double distanceTo(LocationModel other) {
    const double earthRadius = 6371;
    final dLat = _degreesToRadians(other.latitude - latitude);
    final dLon = _degreesToRadians(other.longitude - longitude);
    final a = (dLat / 2).abs() * (dLat / 2).abs() +
        latitude.abs() *
            other.latitude.abs() *
            (dLon / 2).abs() *
            (dLon / 2).abs();
    final c = 2 * (a.abs().clamp(0, 1));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) => degrees * 3.141592653589793 / 180;
}
