// lib/models/service.dart
class Service {
  final int? id;
  final String name;
  final String description;
  final double price;
  final String category; // e.g., 'checkup', 'vaccination', 'emergency'
  final bool isActive;

  Service({
    this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'is_active': isActive ? 1 : 0,
  };

  factory Service.fromMap(Map<String, dynamic> m) => Service(
    id: m['id'],
    name: m['name'] ?? '',
    description: m['description'] ?? '',
    price: (m['price'] as num).toDouble(),
    category: m['category'] ?? '',
    isActive: m['is_active'] == 1,
  );

  Service copyWith({
    int? id,
    String? name,
    String? description,
    double? price,
    String? category,
    bool? isActive,
  }) {
    return Service(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
    );
  }
}
