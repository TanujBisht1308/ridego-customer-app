class SavedPlace {
  final String id;
  final String label;
  final String address;
  final double latitude;
  final double longitude;
  final String icon;

  const SavedPlace({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.icon = 'place',
  });

  factory SavedPlace.fromJson(Map<String, dynamic> json) {
    return SavedPlace(
      id: json['id'] as String,
      label: json['label'] as String,
      address: json['address'] as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      icon: json['icon'] as String? ?? 'place',
    );
  }
}