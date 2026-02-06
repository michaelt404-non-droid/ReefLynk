class Livestock {
  final int? id;
  final String commonName;
  final String speciesType;
  final int quantity;
  final String? source;
  final double? cost;
  final DateTime dateAdded;
  final DateTime? createdAt;
  final String? imagePath; // Renamed from imageUrl

  Livestock({
    this.id,
    required this.commonName,
    required this.speciesType,
    this.quantity = 1,
    this.source,
    this.cost,
    required this.dateAdded,
    this.createdAt,
    this.imagePath, // Renamed from imageUrl
  });

  factory Livestock.fromMap(Map<String, dynamic> map) {
    return Livestock(
      id: map['id'],
      commonName: map['common_name'],
      speciesType: map['species_type'],
      quantity: map['quantity'] ?? 1,
      source: map['source'],
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      dateAdded: DateTime.parse(map['date_added']),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      imagePath: map['image_path'], // Renamed from image_url
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'common_name': commonName,
      'species_type': speciesType,
      'quantity': quantity,
      'source': source,
      'cost': cost,
      'date_added': dateAdded.toIso8601String().split('T').first,
      'image_path': imagePath, // Renamed from image_url
    };
  }

  Livestock copyWith({
    int? id,
    String? commonName,
    String? speciesType,
    int? quantity,
    String? source,
    double? cost,
    DateTime? dateAdded,
    DateTime? createdAt,
    String? imagePath, // Renamed from imageUrl
  }) {
    return Livestock(
      id: id ?? this.id,
      commonName: commonName ?? this.commonName,
      speciesType: speciesType ?? this.speciesType,
      quantity: quantity ?? this.quantity,
      source: source ?? this.source,
      cost: cost ?? this.cost,
      dateAdded: dateAdded ?? this.dateAdded,
      createdAt: createdAt ?? this.createdAt,
      imagePath: imagePath ?? this.imagePath, // Renamed from imageUrl
    );
  }

  static const speciesTypes = ['Fish', 'Coral', 'Invertebrate', 'Cleanup Crew'];
}
