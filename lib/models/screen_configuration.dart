/// Model for dynamic screen configuration per role
/// Allows admin to control which screens each role can access
class ScreenConfiguration {
  final String? id;
  final String role; // 'admin', 'doctor', 'driver', 'owner'
  final String screenId; // unique identifier for the screen
  final String screenName;
  final String? screenDescription;
  final bool isEnabled;
  final bool isVisible;
  final int sortOrder;
  final String? iconName;
  final Map<String, dynamic>? customSettings;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? category; // for grouping screens (e.g., 'Main', 'Settings', 'Reports')
  final bool requiresVerification; // for doctors/drivers that need verification
  final List<String>? permissions; // additional permission checks
  
  // Design/Style fields for screen customization
  final String? backgroundColor;
  final String? textColor;
  final String? accentColor;
  final double? fontSize;
  final double? borderRadius;
  final double? padding;
  final bool useCardStyle;
  final bool useShadow;
  final String? fontFamily;
  final String? headerBackgroundColor;
  final String? bottomNavColor;
  final double? iconSize;

  ScreenConfiguration({
    this.id,
    required this.role,
    required this.screenId,
    required this.screenName,
    this.screenDescription,
    this.isEnabled = true,
    this.isVisible = true,
    this.sortOrder = 0,
    this.iconName,
    this.customSettings,
    this.createdAt,
    this.updatedAt,
    this.category,
    this.requiresVerification = false,
    this.permissions,
    this.backgroundColor,
    this.textColor,
    this.accentColor,
    this.fontSize,
    this.borderRadius,
    this.padding,
    this.useCardStyle = true,
    this.useShadow = true,
    this.fontFamily,
    this.headerBackgroundColor,
    this.bottomNavColor,
    this.iconSize,
  });

  factory ScreenConfiguration.fromMap(Map<String, dynamic> map) {
    return ScreenConfiguration(
      id: map['id'] as String?,
      role: map['role'] as String,
      screenId: map['screen_id'] as String,
      screenName: map['screen_name'] as String,
      screenDescription: map['screen_description'] as String?,
      isEnabled: map['is_enabled'] as bool? ?? true,
      isVisible: map['is_visible'] as bool? ?? true,
      sortOrder: map['sort_order'] as int? ?? 0,
      iconName: map['icon_name'] as String?,
      customSettings: map['custom_settings'] as Map<String, dynamic>?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
      category: map['category'] as String?,
      requiresVerification: map['requires_verification'] as bool? ?? false,
      permissions: map['permissions'] != null
          ? List<String>.from(map['permissions'] as List)
          : null,
      // Design fields
      backgroundColor: map['background_color'] as String?,
      textColor: map['text_color'] as String?,
      accentColor: map['accent_color'] as String?,
      fontSize: (map['font_size'] as num?)?.toDouble(),
      borderRadius: (map['border_radius'] as num?)?.toDouble(),
      padding: (map['padding'] as num?)?.toDouble(),
      useCardStyle: map['use_card_style'] as bool? ?? true,
      useShadow: map['use_shadow'] as bool? ?? true,
      fontFamily: map['font_family'] as String?,
      headerBackgroundColor: map['header_background_color'] as String?,
      bottomNavColor: map['bottom_nav_color'] as String?,
      iconSize: (map['icon_size'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'role': role,
      'screen_id': screenId,
      'screen_name': screenName,
      'screen_description': screenDescription,
      'is_enabled': isEnabled,
      'is_visible': isVisible,
      'sort_order': sortOrder,
      'icon_name': iconName,
      'custom_settings': customSettings,
      if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      'category': category,
      'requires_verification': requiresVerification,
      'permissions': permissions,
      // Design fields
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (textColor != null) 'text_color': textColor,
      if (accentColor != null) 'accent_color': accentColor,
      if (fontSize != null) 'font_size': fontSize,
      if (borderRadius != null) 'border_radius': borderRadius,
      if (padding != null) 'padding': padding,
      'use_card_style': useCardStyle,
      'use_shadow': useShadow,
      if (fontFamily != null) 'font_family': fontFamily,
      if (headerBackgroundColor != null) 'header_background_color': headerBackgroundColor,
      if (bottomNavColor != null) 'bottom_nav_color': bottomNavColor,
      if (iconSize != null) 'icon_size': iconSize,
    };
  }

  ScreenConfiguration copyWith({
    String? id,
    String? role,
    String? screenId,
    String? screenName,
    String? screenDescription,
    bool? isEnabled,
    bool? isVisible,
    int? sortOrder,
    String? iconName,
    Map<String, dynamic>? customSettings,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? category,
    bool? requiresVerification,
    List<String>? permissions,
    String? backgroundColor,
    String? textColor,
    String? accentColor,
    double? fontSize,
    double? borderRadius,
    double? padding,
    bool? useCardStyle,
    bool? useShadow,
    String? fontFamily,
    String? headerBackgroundColor,
    String? bottomNavColor,
    double? iconSize,
  }) {
    return ScreenConfiguration(
      id: id ?? this.id,
      role: role ?? this.role,
      screenId: screenId ?? this.screenId,
      screenName: screenName ?? this.screenName,
      screenDescription: screenDescription ?? this.screenDescription,
      isEnabled: isEnabled ?? this.isEnabled,
      isVisible: isVisible ?? this.isVisible,
      sortOrder: sortOrder ?? this.sortOrder,
      iconName: iconName ?? this.iconName,
      customSettings: customSettings ?? this.customSettings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      category: category ?? this.category,
      requiresVerification: requiresVerification ?? this.requiresVerification,
      permissions: permissions ?? this.permissions,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      accentColor: accentColor ?? this.accentColor,
      fontSize: fontSize ?? this.fontSize,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      useCardStyle: useCardStyle ?? this.useCardStyle,
      useShadow: useShadow ?? this.useShadow,
      fontFamily: fontFamily ?? this.fontFamily,
      headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
      bottomNavColor: bottomNavColor ?? this.bottomNavColor,
      iconSize: iconSize ?? this.iconSize,
    );
  }

  // Available roles
  static const List<String> availableRoles = [
    'admin',
    'doctor',
    'driver',
    'owner',
  ];

  // Available screen categories
  static const List<String> availableCategories = [
    'Main',
    'Management',
    'Reports',
    'Settings',
    'Profile',
    'Support',
    'System',
  ];

  // Available icons mapping
  static const Map<String, String> iconMapping = {
    'people': 'people',
    'medical_services': 'medical_services',
    'analytics': 'analytics',
    'verified': 'verified',
    'backup': 'backup',
    'directions_car': 'directions_car',
    'location_on': 'location_on',
    'settings': 'settings',
    'history': 'history',
    'description': 'description',
    'calendar_today': 'calendar_today',
    'local_hospital': 'local_hospital',
    'person': 'person',
    'pets': 'pets',
    'payment': 'payment',
    'shopping_cart': 'shopping_cart',
    'map': 'map',
    'emergency': 'emergency',
    'inventory': 'inventory',
    'science': 'science',
    'assignment': 'assignment',
    'folder': 'folder',
    'home': 'home',
    'monitoring': 'monitoring',
    'vaccines': 'vaccines',
    'healing': 'healing',
  };

  // Predefined screens for each role
  static List<ScreenConfiguration> getDefaultScreensForRole(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return _getAdminDefaultScreens();
      case 'doctor':
        return _getDoctorDefaultScreens();
      case 'driver':
        return _getDriverDefaultScreens();
      case 'owner':
        return _getOwnerDefaultScreens();
      default:
        return [];
    }
  }

  static List<ScreenConfiguration> _getAdminDefaultScreens() {
    return [
      ScreenConfiguration(
        role: 'admin',
        screenId: 'user_management',
        screenName: 'User Management',
        screenDescription: 'Manage users, roles, and permissions',
        iconName: 'people',
        category: 'Management',
        sortOrder: 1,
      ),
      ScreenConfiguration(
        role: 'admin',
        screenId: 'service_management',
        screenName: 'Service Management',
        screenDescription: 'Manage clinic services and pricing',
        iconName: 'medical_services',
        category: 'Management',
        sortOrder: 2,
      ),
      ScreenConfiguration(
        role: 'admin',
        screenId: 'reporting',
        screenName: 'Reporting & Analytics',
        screenDescription: 'View reports and analytics',
        iconName: 'analytics',
        category: 'Reports',
        sortOrder: 3,
      ),
      ScreenConfiguration(
        role: 'admin',
        screenId: 'compliance',
        screenName: 'Compliance Records',
        screenDescription: 'Manage compliance and verification records',
        iconName: 'verified',
        category: 'Management',
        sortOrder: 4,
      ),
      ScreenConfiguration(
        role: 'admin',
        screenId: 'data_management',
        screenName: 'Data Backup & Restore',
        screenDescription: 'Backup and restore system data',
        iconName: 'backup',
        category: 'System',
        sortOrder: 5,
      ),
      ScreenConfiguration(
        role: 'admin',
        screenId: 'van_management',
        screenName: 'Van Management',
        screenDescription: 'Manage clinic vans and assignments',
        iconName: 'directions_car',
        category: 'Management',
        sortOrder: 6,
      ),
      ScreenConfiguration(
        role: 'admin',
        screenId: 'area_management',
        screenName: 'Area Management',
        screenDescription: 'Manage service areas and coverage',
        iconName: 'location_on',
        category: 'Management',
        sortOrder: 7,
      ),
      ScreenConfiguration(
        role: 'admin',
        screenId: 'system_settings',
        screenName: 'System Settings',
        screenDescription: 'Configure system-wide settings',
        iconName: 'settings',
        category: 'System',
        sortOrder: 8,
      ),
      ScreenConfiguration(
        role: 'admin',
        screenId: 'audit_logs',
        screenName: 'Audit Logs',
        screenDescription: 'View system audit logs',
        iconName: 'history',
        category: 'System',
        sortOrder: 9,
      ),
      ScreenConfiguration(
        role: 'admin',
        screenId: 'page_management',
        screenName: 'Page Management',
        screenDescription: 'Manage CMS pages and content',
        iconName: 'description',
        category: 'Management',
        sortOrder: 10,
      ),
      ScreenConfiguration(
        role: 'admin',
        screenId: 'screen_management',
        screenName: 'Screen Management',
        screenDescription: 'Configure screens for all roles',
        iconName: 'monitoring',
        category: 'System',
        sortOrder: 11,
      ),
    ];
  }

  static List<ScreenConfiguration> _getDoctorDefaultScreens() {
    return [
      ScreenConfiguration(
        role: 'doctor',
        screenId: 'appointments',
        screenName: 'Appointments',
        screenDescription: 'Manage your appointments',
        iconName: 'calendar_today',
        category: 'Main',
        sortOrder: 1,
      ),
      ScreenConfiguration(
        role: 'doctor',
        screenId: 'medical_records',
        screenName: 'Medical Records',
        screenDescription: 'View and manage patient records',
        iconName: 'folder',
        category: 'Main',
        sortOrder: 2,
      ),
      ScreenConfiguration(
        role: 'doctor',
        screenId: 'emergency_cases',
        screenName: 'Emergency Cases',
        screenDescription: 'Handle emergency cases',
        iconName: 'emergency',
        category: 'Main',
        sortOrder: 3,
      ),
      ScreenConfiguration(
        role: 'doctor',
        screenId: 'inventory',
        screenName: 'Inventory',
        screenDescription: 'Manage medical supplies inventory',
        iconName: 'inventory',
        category: 'Management',
        sortOrder: 4,
      ),
      ScreenConfiguration(
        role: 'doctor',
        screenId: 'schedule_settings',
        screenName: 'Schedule Settings',
        screenDescription: 'Configure your availability',
        iconName: 'settings',
        category: 'Settings',
        sortOrder: 5,
      ),
      ScreenConfiguration(
        role: 'doctor',
        screenId: 'profile',
        screenName: 'Profile',
        screenDescription: 'Manage your profile and documents',
        iconName: 'person',
        category: 'Profile',
        sortOrder: 6,
      ),
      ScreenConfiguration(
        role: 'doctor',
        screenId: 'van_selection',
        screenName: 'Van Selection',
        screenDescription: 'Select your assigned van',
        iconName: 'directions_car',
        category: 'Main',
        sortOrder: 7,
      ),
    ];
  }

  static List<ScreenConfiguration> _getDriverDefaultScreens() {
    return [
      ScreenConfiguration(
        role: 'driver',
        screenId: 'van_dashboard',
        screenName: 'Van Dashboard',
        screenDescription: 'Your van operations dashboard',
        iconName: 'directions_car',
        category: 'Main',
        sortOrder: 1,
      ),
      ScreenConfiguration(
        role: 'driver',
        screenId: 'doctor_selection',
        screenName: 'Doctor Selection',
        screenDescription: 'View assigned doctors',
        iconName: 'people',
        category: 'Main',
        sortOrder: 2,
      ),
      ScreenConfiguration(
        role: 'driver',
        screenId: 'emergency_response',
        screenName: 'Emergency Response',
        screenDescription: 'Emergency case coordination',
        iconName: 'emergency',
        category: 'Main',
        sortOrder: 3,
      ),
      ScreenConfiguration(
        role: 'driver',
        screenId: 'route_planning',
        screenName: 'Route Planning',
        screenDescription: 'Plan your daily routes',
        iconName: 'map',
        category: 'Main',
        sortOrder: 4,
      ),
      ScreenConfiguration(
        role: 'driver',
        screenId: 'van_selection',
        screenName: 'Van Selection',
        screenDescription: 'Select your assigned van',
        iconName: 'local_hospital',
        category: 'Main',
        sortOrder: 5,
      ),
      ScreenConfiguration(
        role: 'driver',
        screenId: 'profile',
        screenName: 'Profile',
        screenDescription: 'Manage your profile',
        iconName: 'person',
        category: 'Profile',
        sortOrder: 6,
      ),
    ];
  }

  static List<ScreenConfiguration> _getOwnerDefaultScreens() {
    return [
      ScreenConfiguration(
        role: 'owner',
        screenId: 'my_pets',
        screenName: 'My Pets',
        screenDescription: 'Manage your pets',
        iconName: 'pets',
        category: 'Main',
        sortOrder: 1,
      ),
      ScreenConfiguration(
        role: 'owner',
        screenId: 'book_appointment',
        screenName: 'Book Appointment',
        screenDescription: 'Book a new appointment',
        iconName: 'calendar_today',
        category: 'Main',
        sortOrder: 2,
      ),
      ScreenConfiguration(
        role: 'owner',
        screenId: 'my_appointments',
        screenName: 'My Appointments',
        screenDescription: 'View your appointments',
        iconName: 'assignment',
        category: 'Main',
        sortOrder: 3,
      ),
      ScreenConfiguration(
        role: 'owner',
        screenId: 'medical_history',
        screenName: 'Medical History',
        screenDescription: 'View pet medical history',
        iconName: 'medical_services',
        category: 'Main',
        sortOrder: 4,
      ),
      ScreenConfiguration(
        role: 'owner',
        screenId: 'medical_documents',
        screenName: 'Medical Documents',
        screenDescription: 'Access pet documents',
        iconName: 'folder',
        category: 'Main',
        sortOrder: 5,
      ),
      ScreenConfiguration(
        role: 'owner',
        screenId: 'driver_tracking',
        screenName: 'Driver Tracking',
        screenDescription: 'Track your appointment driver',
        iconName: 'map',
        category: 'Main',
        sortOrder: 6,
      ),
      ScreenConfiguration(
        role: 'owner',
        screenId: 'payment_history',
        screenName: 'Payment History',
        screenDescription: 'View payment records',
        iconName: 'payment',
        category: 'Main',
        sortOrder: 7,
      ),
      ScreenConfiguration(
        role: 'owner',
        screenId: 'profile',
        screenName: 'Profile',
        screenDescription: 'Manage your profile',
        iconName: 'person',
        category: 'Profile',
        sortOrder: 8,
      ),
    ];
  }
}
