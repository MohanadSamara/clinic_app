class VehicleCheck {
  final int? id;
  final int driverId;
  final DateTime checkDate;
  final String vehicleCondition; // 'good', 'needs_attention', 'critical'
  final bool fuelLevel; // true if adequate
  final bool tiresCondition;
  final bool lightsWorking;
  final bool medicalEquipmentPresent;
  final List<String>? missingEquipment;
  final List<String>? malfunctioningEquipment;
  final String? notes;
  final String? photoPath;

  VehicleCheck({
    this.id,
    required this.driverId,
    required this.checkDate,
    required this.vehicleCondition,
    required this.fuelLevel,
    required this.tiresCondition,
    required this.lightsWorking,
    required this.medicalEquipmentPresent,
    this.missingEquipment,
    this.malfunctioningEquipment,
    this.notes,
    this.photoPath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'driver_id': driverId,
      'check_date': checkDate.toIso8601String(),
      'vehicle_condition': vehicleCondition,
      'fuel_level': fuelLevel ? 1 : 0,
      'tires_condition': tiresCondition ? 1 : 0,
      'lights_working': lightsWorking ? 1 : 0,
      'medical_equipment_present': medicalEquipmentPresent ? 1 : 0,
      'missing_equipment': missingEquipment?.join(','),
      'malfunctioning_equipment': malfunctioningEquipment?.join(','),
      'notes': notes,
      'photo_path': photoPath,
    };
  }

  factory VehicleCheck.fromMap(Map<String, dynamic> map) {
    return VehicleCheck(
      id: map['id'],
      driverId: map['driver_id'],
      checkDate: DateTime.parse(map['check_date']),
      vehicleCondition: map['vehicle_condition'],
      fuelLevel: map['fuel_level'] == 1,
      tiresCondition: map['tires_condition'] == 1,
      lightsWorking: map['lights_working'] == 1,
      medicalEquipmentPresent: map['medical_equipment_present'] == 1,
      missingEquipment: map['missing_equipment'] != null
          ? (map['missing_equipment'] as String).split(',')
          : null,
      malfunctioningEquipment: map['malfunctioning_equipment'] != null
          ? (map['malfunctioning_equipment'] as String).split(',')
          : null,
      notes: map['notes'],
      photoPath: map['photo_path'],
    );
  }
}
