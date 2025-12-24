// lib/models/inventory_item.dart
class InventoryItem {
  final int? id;
  final String name;
  final String description;
  final int quantity;
  final int minThreshold;
  final String unit; // e.g., 'pieces', 'ml', 'mg'
  final double cost;
  final String category;

  InventoryItem({
    this.id,
    required this.name,
    required this.description,
    required this.quantity,
    required this.minThreshold,
    required this.unit,
    required this.cost,
    required this.category,
  });

  bool get isLowStock => quantity <= minThreshold;

  Map<String, dynamic> toMap() => {
    if (id != null) 'id': id,
    'name': name,
    'description': description,
    'quantity': quantity,
    'min_threshold': minThreshold,
    'unit': unit,
    'cost': cost,
    'category': category,
  };

  factory InventoryItem.fromMap(Map<String, dynamic> m) => InventoryItem(
    id: m['id'],
    name: m['name'] ?? '',
    description: m['description'] ?? '',
    quantity: m['quantity'] ?? 0,
    minThreshold: m['min_threshold'] ?? 0,
    unit: m['unit'] ?? '',
    cost: (m['cost'] as num).toDouble(),
    category: m['category'] ?? '',
  );

  InventoryItem copyWith({
    int? id,
    String? name,
    String? description,
    int? quantity,
    int? minThreshold,
    String? unit,
    double? cost,
    String? category,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
      unit: unit ?? this.unit,
      cost: cost ?? this.cost,
      category: category ?? this.category,
    );
  }
}







