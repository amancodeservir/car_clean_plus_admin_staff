class StaffAccount {
  StaffAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.token = '',
    this.onShift = false,
    this.branch = '',
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String token;
  final bool onShift;
  final String branch;

  bool get isAdmin => role == 'admin' || role == 'superadmin';
  bool get isSuperadmin => role == 'superadmin';
  bool get isCustomer => role == 'customer';
  bool get isStaff => role == 'staff';

  factory StaffAccount.fromJson(Map<String, dynamic> json, {String token = ''}) {
    return StaffAccount(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      role: json['role']?.toString() ?? 'customer',
      token: token,
      onShift: json['onShift'] == true,
      branch: json['branch']?.toString() ?? '',
    );
  }
}

class BookingRecord {
  BookingRecord({
    required this.id,
    required this.service,
    required this.carName,
    required this.carCategory,
    required this.address,
    required this.city,
    required this.date,
    required this.timeSlot,
    required this.customerName,
    required this.mobile,
    required this.instructions,
    required this.price,
    required this.paymentMethod,
    required this.status,
    required this.source,
    required this.createdAt,
    this.assignedStaffId = '',
    this.assignedStaffName = '',
    this.latitude,
    this.longitude,
    this.collectedCash = 0,
    this.collectedUpi = 0,
    this.paymentStatus = '',
    this.hasBeforePhoto = false,
    this.hasAfterPhoto = false,
    this.clockedIn = false,
  });

  final String id;
  final String service;
  final String carName;
  final String carCategory;
  final String address;
  final String city;
  final String date;
  final String timeSlot;
  final String customerName;
  final String mobile;
  final String instructions;
  final num price;
  final String paymentMethod;
  final String status;
  final String source;
  final String createdAt;
  final String assignedStaffId;
  final String assignedStaffName;
  final double? latitude;
  final double? longitude;
  final num collectedCash;
  final num collectedUpi;
  final String paymentStatus;
  final bool hasBeforePhoto;
  final bool hasAfterPhoto;
  final bool clockedIn;

  num get collected => collectedCash + collectedUpi;
  num get due => price - collected < 0 ? 0 : price - collected;

  factory BookingRecord.fromJson(Map<String, dynamic> json) {
    final car = json['carModel'] is Map
        ? Map<String, dynamic>.from(json['carModel'] as Map)
        : <String, dynamic>{};
    final location = json['location'] is Map
        ? Map<String, dynamic>.from(json['location'] as Map)
        : <String, dynamic>{};
    final customer = json['customerDetails'] is Map
        ? Map<String, dynamic>.from(json['customerDetails'] as Map)
        : <String, dynamic>{};
    final priceRaw = json['finalPrice'];
    final assigned = json['assignedStaff'];
    final assignedMap = assigned is Map
        ? Map<String, dynamic>.from(assigned)
        : <String, dynamic>{};
    return BookingRecord(
      id: json['_id']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      carName: car['name']?.toString() ?? '',
      carCategory: car['category']?.toString() ?? '',
      address: location['address']?.toString() ?? '',
      city: location['city']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      timeSlot: json['timeSlot']?.toString() ?? '',
      customerName: customer['fullName']?.toString() ?? '',
      mobile: customer['mobile']?.toString() ?? '',
      instructions: customer['instructions']?.toString() ?? '',
      price: priceRaw is num ? priceRaw : num.tryParse('$priceRaw') ?? 0,
      paymentMethod: json['paymentMethod']?.toString() ?? '',
      status: (json['status']?.toString() ?? 'pending').toLowerCase(),
      source: json['bookingSource']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      assignedStaffId: assignedMap['_id']?.toString() ?? '',
      assignedStaffName: assignedMap['name']?.toString() ?? '',
      latitude: location['latitude'] is num ? (location['latitude'] as num).toDouble() : null,
      longitude: location['longitude'] is num ? (location['longitude'] as num).toDouble() : null,
      collectedCash: json['collectedCash'] is num ? json['collectedCash'] as num : num.tryParse('${json['collectedCash']}') ?? 0,
      collectedUpi: json['collectedUpi'] is num ? json['collectedUpi'] as num : num.tryParse('${json['collectedUpi']}') ?? 0,
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      hasBeforePhoto: (json['beforePhoto']?.toString() ?? '').isNotEmpty,
      hasAfterPhoto: (json['afterPhoto']?.toString() ?? '').isNotEmpty,
      clockedIn: (json['clockedInAt']?.toString() ?? '').isNotEmpty,
    );
  }
}

class DashboardStats {
  DashboardStats({
    required this.totalBookings,
    required this.pendingBookings,
    required this.totalRevenue,
    required this.totalInquiries,
    required this.recentBookings,
  });

  final int totalBookings;
  final int pendingBookings;
  final num totalRevenue;
  final int totalInquiries;
  final List<BookingRecord> recentBookings;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final recent = json['recentBookings'];
    return DashboardStats(
      totalBookings: _asInt(json['totalBookings']),
      pendingBookings: _asInt(json['pendingBookings']),
      totalRevenue: json['totalRevenue'] is num
          ? json['totalRevenue'] as num
          : num.tryParse('${json['totalRevenue']}') ?? 0,
      totalInquiries: _asInt(json['totalInquiries']),
      recentBookings: recent is List
          ? recent
              .whereType<Map>()
              .map((item) => BookingRecord.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
    );
  }
}

class ContactMessage {
  ContactMessage({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.subject,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String subject;
  final String message;
  final String createdAt;

  factory ContactMessage.fromJson(Map<String, dynamic> json) {
    return ContactMessage(
      id: json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class GalleryItem {
  GalleryItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.isActive,
    required this.order,
  });

  final String id;
  final String title;
  final String description;
  final String category;
  final String imageUrl;
  final bool isActive;
  final int order;

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      isActive: json['isActive'] != false,
      order: _asInt(json['order']),
    );
  }
}

class FestivalSetting {
  FestivalSetting({
    required this.activeFestival,
    required this.isOfferActive,
    required this.customOfferPrice,
    required this.customDiscount,
  });

  final String activeFestival;
  final bool isOfferActive;
  final String customOfferPrice;
  final String customDiscount;

  factory FestivalSetting.fromJson(Map<String, dynamic> json) {
    return FestivalSetting(
      activeFestival: json['activeFestival']?.toString() ?? 'GENERAL',
      isOfferActive: json['isOfferActive'] == true,
      customOfferPrice: json['customOfferPrice']?.toString() ?? '',
      customDiscount: json['customDiscount']?.toString() ?? '',
    );
  }
}

class DeskAlert {
  DeskAlert({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool read;
  final String createdAt;

  factory DeskAlert.fromJson(Map<String, dynamic> json) {
    return DeskAlert(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      read: json['read'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class StaffDaySummary {
  StaffDaySummary({
    required this.date,
    required this.jobs,
    required this.pending,
    required this.active,
    required this.completed,
    required this.collectedCash,
    required this.collectedUpi,
    required this.expected,
  });

  final String date;
  final int jobs;
  final int pending;
  final int active;
  final int completed;
  final num collectedCash;
  final num collectedUpi;
  final num expected;

  factory StaffDaySummary.fromJson(Map<String, dynamic> json) {
    num asNum(Object? value) => value is num ? value : num.tryParse('$value') ?? 0;
    return StaffDaySummary(
      date: json['date']?.toString() ?? '',
      jobs: _asInt(json['jobs']),
      pending: _asInt(json['pending']),
      active: _asInt(json['active']),
      completed: _asInt(json['completed']),
      collectedCash: asNum(json['collectedCash']),
      collectedUpi: asNum(json['collectedUpi']),
      expected: asNum(json['expected']),
    );
  }
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse('$value') ?? 0;
}

List<T> mapList<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return [];
  return raw
      .whereType<Map>()
      .map((item) => parse(Map<String, dynamic>.from(item)))
      .toList();
}
