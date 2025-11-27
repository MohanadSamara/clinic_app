// lib/models/service.dart
class Service {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String category; // e.g., 'checkup', 'vaccination', 'emergency'
  final bool isActive;
  final double? promotionalPrice; // Optional promotional price

  Service({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.isActive = true,
    this.promotionalPrice,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'is_active': isActive ? 1 : 0,
    if (promotionalPrice != null) 'promotional_price': promotionalPrice,
  };

  factory Service.fromMap(Map<String, dynamic> m) => Service(
    id: m['id'] is int ? m['id'] as int : null,
    name: m['name']?.toString() ?? '',
    description: m['description']?.toString() ?? '',
    price: m['price'] is num ? (m['price'] as num).toDouble() : 0.0,
    category: m['category']?.toString() ?? '',
    isActive: m['is_active'] == 1,
    promotionalPrice: m['promotional_price'] is num
        ? (m['promotional_price'] as num).toDouble()
        : null,
  );

  Service copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isActive,
    double? promotionalPrice,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      promotionalPrice: promotionalPrice ?? this.promotionalPrice,
    );
  }
}
