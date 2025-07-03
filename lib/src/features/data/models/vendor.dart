/// Temporary stub for Vendor model - to be implemented later
class Vendor {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final bool isActive;
  final DateTime createdAt;
  final VendorBusinessInfo businessInfo;

  const Vendor({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.isActive = true,
    required this.createdAt,
    required this.businessInfo,
  });

  factory Vendor.fromJson(Map<String, dynamic> json) {
    return Vendor(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phone_number'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      businessInfo: VendorBusinessInfo.fromJson(json['business_info'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'business_info': businessInfo.toJson(),
    };
  }
}

class VendorBusinessInfo {
  final String businessName;
  final String? description;
  final String? address;
  final VendorOperatingHours operatingHours;

  const VendorBusinessInfo({
    required this.businessName,
    this.description,
    this.address,
    required this.operatingHours,
  });

  factory VendorBusinessInfo.fromJson(Map<String, dynamic> json) {
    return VendorBusinessInfo(
      businessName: json['business_name'] ?? '',
      description: json['description'],
      address: json['address'],
      operatingHours: VendorOperatingHours.fromJson(json['operating_hours'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'business_name': businessName,
      'description': description,
      'address': address,
      'operating_hours': operatingHours.toJson(),
    };
  }
}

class VendorOperatingHours {
  final Map<String, DaySchedule> schedule;

  const VendorOperatingHours({
    required this.schedule,
  });

  factory VendorOperatingHours.fromJson(Map<String, dynamic> json) {
    final scheduleMap = <String, DaySchedule>{};
    final scheduleData = json['schedule'] as Map<String, dynamic>? ?? {};
    
    for (final entry in scheduleData.entries) {
      scheduleMap[entry.key] = DaySchedule.fromJson(entry.value as Map<String, dynamic>? ?? {});
    }

    return VendorOperatingHours(schedule: scheduleMap);
  }

  Map<String, dynamic> toJson() {
    final scheduleMap = <String, dynamic>{};
    for (final entry in schedule.entries) {
      scheduleMap[entry.key] = entry.value.toJson();
    }
    return {'schedule': scheduleMap};
  }
}

class DaySchedule {
  final bool isOpen;
  final String? openTime;
  final String? closeTime;

  const DaySchedule({
    required this.isOpen,
    this.openTime,
    this.closeTime,
  });

  factory DaySchedule.fromJson(Map<String, dynamic> json) {
    return DaySchedule(
      isOpen: json['is_open'] ?? false,
      openTime: json['open_time'],
      closeTime: json['close_time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_open': isOpen,
      'open_time': openTime,
      'close_time': closeTime,
    };
  }
}
