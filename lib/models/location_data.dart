// lib/models/location_data.dart
import 'dart:math';

class District {
  final String name;
  final String arabicName;
  final List<String> subAreas;
  final double centerLat;
  final double centerLng;
  final int populationDensity; // 1-5 scale, 5 being highest

  const District({
    required this.name,
    required this.arabicName,
    required this.subAreas,
    required this.centerLat,
    required this.centerLng,
    required this.populationDensity,
  });

  int get subAreaCount => subAreas.length;
}

class AmmanDistricts {
  static const List<District> allDistricts = [
    District(
      name: 'Amman Qasaba',
      arabicName: 'أمانة عمّان قصبة',
      subAreas: [
        'Downtown Amman',
        'Al-Hussein Medical Center',
        'Al-Madinah',
        'Al-Mufti',
        'Al-Nasr',
        'Al-Quds',
        'Al-Rashid',
        'Al-Weibdeh',
        'Al-Yarmouk',
        'Jabal Al-Luweibdeh',
        'Jabal Al-Qala\'a',
        'Mecca Mall area',
        'Roman Theater area',
        'Zahran',
        'Al-Mansour',
        'Al-Razi',
        'Al-Yasmeen',
        'Jabal Al-Zaitoun',
        'Shmeisani',
        'Al-Manarah',
        'Al-Muqabalayn',
        'Al-Qadisiyah',
        'Khalda',
        'Al-Taown',
        'Al-Swaifyeh',
      ],
      centerLat: 31.9539,
      centerLng: 35.9106,
      populationDensity: 5,
    ),
    District(
      name: 'Al-Jami\'a',
      arabicName: 'الجامعة',
      subAreas: [
        'Al-Jubaiha',
        'University of Jordan',
        'Al-Rawabi',
        'Al-Taown',
        'Khalda',
        'Marj Al-Hamam',
        'Shafa Badran',
        'Sports City',
        'Tabarbour',
        'Tla\' Al-Ali',
        'Um Al-Summaq',
        'Al-Swaifyeh',
        'Wadi Al-Seer',
        'Zahran',
        'Al-Yarmouk',
      ],
      centerLat: 31.8980,
      centerLng: 35.8894,
      populationDensity: 4,
    ),
    District(
      name: 'Marka',
      arabicName: 'مركا',
      subAreas: [
        'Marka',
        'Al-Manarah',
        'Al-Mansour',
        'Al-Muqabalayn',
        'Al-Qadisiyah',
        'Al-Razi',
        'Al-Yasmeen',
        'Jabal Al-Zaitoun',
        'Khalda',
        'Mecca Mall area',
        'Shmeisani',
        'Wadi Al-Seer',
      ],
      centerLat: 31.9856,
      centerLng: 35.9911,
      populationDensity: 4,
    ),
    District(
      name: 'Al-Qweismeh',
      arabicName: 'القويسمة',
      subAreas: [
        'Al-Qweismeh',
        'Abu Alanda',
        'Al-Bayader',
        'Al-Dustour',
        'Al-Hussein',
        'Al-Masmiyeh',
        'Al-Muqabalayn',
        'Al-Rawabi',
        'Jabal Al-Zaitoun',
        'Mecca Mall area',
      ],
      centerLat: 31.9094,
      centerLng: 35.8917,
      populationDensity: 3,
    ),
    District(
      name: 'Wadi Al-Sir',
      arabicName: 'وادي السير',
      subAreas: [
        'Wadi Al-Seer',
        'Al-Rawabi',
        'Al-Swaifyeh',
        'Khalda',
        'Marj Al-Hamam',
        'Shafa Badran',
        'Um Al-Summaq',
        'Zahran',
      ],
      centerLat: 31.8667,
      centerLng: 35.8833,
      populationDensity: 3,
    ),
    District(
      name: 'Al-Jizah',
      arabicName: 'الجيزة',
      subAreas: [
        'Al-Jizah',
        'Al-Bayader',
        'Al-Masmiyeh',
        'Al-Muwaqqar',
        'Naour',
        'Sahab',
      ],
      centerLat: 31.8333,
      centerLng: 35.8833,
      populationDensity: 2,
    ),
    District(
      name: 'Sahab',
      arabicName: 'سحاب',
      subAreas: [
        'Sahab',
        'Al-Jizah',
        'Al-Muwaqqar',
        'Naour',
        'Umm Al-Basateen',
        'Umm Al-Hieran',
        'Umm Al-Summaq',
        'Zahran',
      ],
      centerLat: 31.8667,
      centerLng: 35.9333,
      populationDensity: 3,
    ),
    District(
      name: 'Naour',
      arabicName: 'ناعور',
      subAreas: [
        'Naour',
        'Al-Jizah',
        'Al-Muwaqqar',
        'Sahab',
        'Umm Al-Basateen',
      ],
      centerLat: 31.8333,
      centerLng: 35.9333,
      populationDensity: 2,
    ),
    District(
      name: 'Dabouq',
      arabicName: 'دابوق',
      subAreas: ['Dabouq', 'Al-Muwaqqar', 'Naour', 'Sahab'],
      centerLat: 31.8167,
      centerLng: 35.9500,
      populationDensity: 2,
    ),
  ];

  // Get district by name
  static District? getDistrictByName(String name) {
    // Normalize the input name by removing " district" suffix if present
    String normalizedName = name.toLowerCase().replaceAll(
      RegExp(r'\s+district$'),
      '',
    );
    try {
      return allDistricts.firstWhere(
        (district) =>
            district.name.toLowerCase() == normalizedName ||
            district.arabicName.toLowerCase() == normalizedName,
      );
    } catch (e) {
      return null;
    }
  }

  // Get district containing a sub-area
  static District? getDistrictBySubArea(String subArea) {
    // Normalize the input sub-area by removing " district" suffix if present
    String normalizedSubArea = subArea.toLowerCase().replaceAll(
      RegExp(r'\s+district$'),
      '',
    );
    try {
      return allDistricts.firstWhere(
        (district) =>
            district.subAreas.any(
              (area) => area.toLowerCase() == normalizedSubArea,
            ) ||
            district.name.toLowerCase() == normalizedSubArea ||
            district.arabicName.toLowerCase() == normalizedSubArea,
      );
    } catch (e) {
      return null;
    }
  }

  // Get nearest district to coordinates (simplified - uses center points)
  static District? getNearestDistrict(double lat, double lng) {
    District? nearest;
    double minDistance = double.infinity;

    for (final district in allDistricts) {
      final distance = _calculateDistance(
        lat,
        lng,
        district.centerLat,
        district.centerLng,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = district;
      }
    }

    return nearest;
  }

  // Calculate distance between two points using Haversine formula
  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371000; // meters
    final double dLat = (lat2 - lat1) * (3.141592653589793 / 180);
    final double dLng = (lng2 - lng1) * (3.141592653589793 / 180);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  // Get districts ordered by population density (for driver allocation)
  static List<District> getDistrictsByPriority() {
    return List.from(allDistricts)
      ..sort((a, b) => b.populationDensity.compareTo(a.populationDensity));
  }
}







