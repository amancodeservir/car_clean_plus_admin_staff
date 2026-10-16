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

  StaffAccount copyWith({String? token, bool? onShift}) => StaffAccount(
        id: id,
        name: name,
        email: email,
        phone: phone,
        role: role,
        token: token ?? this.token,
        onShift: onShift ?? this.onShift,
        branch: branch,
      );

  Map<String, dynamic> toJson() => {
        '_id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'onShift': onShift,
        'branch': branch,
      };

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

class DeskReport {
  DeskReport({
    this.note = '',
    this.image = '',
    this.at = '',
    this.byName = '',
  });

  final String note;
  final String image;
  final String at;
  final String byName;

  factory DeskReport.fromJson(Map<String, dynamic> json) {
    return DeskReport(
      note: json['note']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      at: json['at']?.toString() ?? '',
      byName: json['byName']?.toString() ?? '',
    );
  }
}

class TimelineStep {
  const TimelineStep({required this.status, required this.at, this.byName = '', this.byRole = '', this.note = ''});

  final String status;
  final String at;
  final String byName;
  final String byRole;
  final String note;

  factory TimelineStep.fromJson(Map<String, dynamic> json) => TimelineStep(
        status: json['status']?.toString() ?? '',
        at: json['at']?.toString() ?? '',
        byName: json['byName']?.toString() ?? '',
        byRole: json['byRole']?.toString() ?? '',
        note: json['note']?.toString() ?? '',
      );
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
    this.reports = const [],
    this.beforePhoto = '',
    this.afterPhoto = '',
    this.washerName = '',
    this.washerPhone = '',
    this.refundAmount = 0,
    this.timeline = const [],
    this.rating,
    this.review = '',
    this.hasUser = false,
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
  final List<DeskReport> reports;
  final String beforePhoto;
  final String afterPhoto;
  final String washerName;
  final String washerPhone;
  final num refundAmount;
  final List<TimelineStep> timeline;
  final int? rating;
  final String review;
  final bool hasUser;

  bool get isBlocked => status == 'blocked';
  bool get isClosed => status == 'completed' || status == 'cancelled' || status == 'blocked';
  bool get isPaid => paymentStatus.toLowerCase() == 'paid';
  bool get isRefunded => paymentStatus.toLowerCase() == 'refunded';
  bool get isAssigned => assignedStaffId.isNotEmpty;

  /// What can still be returned to the customer.
  num get refundable {
    if (isRefunded) return 0;
    if (isPaid) return collected > price ? collected : price;
    return collected;
  }

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
    final assignedId = assigned is Map ? assignedMap['_id']?.toString() ?? '' : assigned?.toString() ?? '';
    num asNum(Object? value) => value is num ? value : num.tryParse('$value') ?? 0;
    final beforePhoto = json['beforePhoto']?.toString() ?? '';
    final afterPhoto = json['afterPhoto']?.toString() ?? '';
    final assignedName = assignedMap['name']?.toString() ?? '';
    final assignedPhone = assignedMap['phone']?.toString() ?? '';
    final washerName = json['washerName']?.toString() ?? '';
    final washerPhone = json['washerPhone']?.toString() ?? '';
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
      assignedStaffId: assignedId,
      assignedStaffName: assignedName,
      latitude: location['latitude'] is num ? (location['latitude'] as num).toDouble() : null,
      longitude: location['longitude'] is num ? (location['longitude'] as num).toDouble() : null,
      collectedCash: json['collectedCash'] is num ? json['collectedCash'] as num : num.tryParse('${json['collectedCash']}') ?? 0,
      collectedUpi: json['collectedUpi'] is num ? json['collectedUpi'] as num : num.tryParse('${json['collectedUpi']}') ?? 0,
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      hasBeforePhoto: beforePhoto.isNotEmpty,
      hasAfterPhoto: afterPhoto.isNotEmpty,
      clockedIn: (json['clockedInAt']?.toString() ?? '').isNotEmpty,
      reports: mapList(json['reports'], DeskReport.fromJson),
      beforePhoto: beforePhoto,
      afterPhoto: afterPhoto,
      washerName: washerName.isNotEmpty ? washerName : assignedName,
      washerPhone: washerPhone.isNotEmpty ? washerPhone : assignedPhone,
      refundAmount: asNum(json['refundAmount']),
      timeline: mapList(json['timeline'], TimelineStep.fromJson),
      rating: json['rating'] is num ? (json['rating'] as num).toInt() : null,
      review: json['review']?.toString() ?? '',
      hasUser: (json['user']?.toString() ?? '').isNotEmpty,
    );
  }
}

class WeekPoint {
  const WeekPoint({required this.date, required this.count, required this.revenue});

  final String date;
  final int count;
  final num revenue;
}

class DashboardStats {
  DashboardStats({
    required this.totalBookings,
    required this.pendingBookings,
    required this.totalRevenue,
    required this.totalInquiries,
    required this.recentBookings,
    this.week = const [],
    this.statusCounts = const {},
    this.collectedRevenue = 0,
    this.todayBookings = 0,
    this.unassigned = 0,
    this.leads = 0,
    this.today = '',
  });

  final num collectedRevenue;
  final String today;
  final int todayBookings;
  final int unassigned;
  final int leads;
  final int totalBookings;
  final int pendingBookings;
  final num totalRevenue;
  final int totalInquiries;
  final List<BookingRecord> recentBookings;
  final List<WeekPoint>? week;
  final Map<String, int>? statusCounts;

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    final recent = json['recentBookings'];
    final week = json['week'];
    final counts = json['statusCounts'];
    return DashboardStats(
      totalBookings: _asInt(json['totalBookings']),
      pendingBookings: _asInt(json['pendingBookings']),
      totalRevenue: json['totalRevenue'] is num
          ? json['totalRevenue'] as num
          : num.tryParse('${json['totalRevenue']}') ?? 0,
      totalInquiries: _asInt(json['totalInquiries']),
      collectedRevenue: json['collectedRevenue'] is num ? json['collectedRevenue'] as num : 0,
      todayBookings: _asInt(json['todayBookings']),
      unassigned: _asInt(json['unassigned']),
      leads: _asInt(json['leads']),
      today: json['today']?.toString() ?? '',
      recentBookings: recent is List
          ? recent
              .whereType<Map>()
              .map((item) => BookingRecord.fromJson(Map<String, dynamic>.from(item)))
              .toList()
          : const [],
      week: week is List
          ? week.whereType<Map>().map((item) {
              final map = Map<String, dynamic>.from(item);
              return WeekPoint(
                date: map['date']?.toString() ?? '',
                count: _asInt(map['count']),
                revenue: map['revenue'] is num
                    ? map['revenue'] as num
                    : num.tryParse('${map['revenue']}') ?? 0,
              );
            }).toList()
          : const [],
      statusCounts: counts is Map
          ? counts.map((key, value) => MapEntry('$key', _asInt(value)))
          : const {},
    );
  }
}

class LedgerEntry {
  LedgerEntry({
    required this.id,
    required this.bookingId,
    required this.kind,
    required this.amount,
    required this.method,
    required this.paymentStatus,
    required this.bookingStatus,
    required this.customerName,
    required this.service,
    required this.date,
    required this.at,
  });

  final String id;
  final String bookingId;
  final String kind;
  final num amount;
  final String method;
  final String paymentStatus;
  final String bookingStatus;
  final String customerName;
  final String service;
  final String date;
  final String at;

  bool get isRefund => kind == 'refund';

  factory LedgerEntry.fromJson(Map<String, dynamic> json) {
    final amount = json['amount'];
    final booking = json['booking'];
    return LedgerEntry(
      id: json['_id']?.toString() ?? '',
      bookingId: booking is Map ? booking['_id']?.toString() ?? '' : booking?.toString() ?? '',
      kind: json['kind']?.toString() ?? 'payment',
      amount: amount is num ? amount : num.tryParse('$amount') ?? 0,
      method: json['method']?.toString() ?? '',
      paymentStatus: json['paymentStatus']?.toString() ?? '',
      bookingStatus: json['bookingStatus']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      service: json['service']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
      at: json['at']?.toString() ?? '',
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
    this.bookingId = '',
  });

  final String id;
  final String title;
  final String body;
  final bool read;
  final String createdAt;
  final String bookingId;

  factory DeskAlert.fromJson(Map<String, dynamic> json) {
    return DeskAlert(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      read: json['read'] == true,
      createdAt: json['createdAt']?.toString() ?? '',
      bookingId: json['booking'] is Map
          ? (json['booking'] as Map)['_id']?.toString() ?? ''
          : json['booking']?.toString() ?? '',
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

class ChatMessage {
  const ChatMessage({required this.id, required this.body, required this.fromRole, required this.userId, required this.at});

  final String id;
  final String body;
  final String fromRole;
  final String userId;
  final String at;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: json['_id']?.toString() ?? '',
        body: json['body']?.toString() ?? '',
        fromRole: json['fromRole']?.toString() ?? 'customer',
        userId: json['user']?.toString() ?? '',
        at: json['createdAt']?.toString() ?? '',
      );
}

/// One booking's conversation in the desk inbox.
class InboxThread {
  const InboxThread({
    required this.bookingId,
    required this.customer,
    required this.service,
    required this.date,
    required this.timeSlot,
    required this.status,
    required this.last,
    required this.lastFrom,
    required this.at,
    required this.count,
    required this.waiting,
  });

  final String bookingId;
  final String customer;
  final String service;
  final String date;
  final String timeSlot;
  final String status;
  final String last;
  final String lastFrom;
  final String at;
  final int count;
  final bool waiting;

  factory InboxThread.fromJson(Map<String, dynamic> json) => InboxThread(
        bookingId: json['booking']?.toString() ?? '',
        customer: json['customer']?.toString() ?? 'Customer',
        service: json['service']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        timeSlot: json['timeSlot']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        last: json['last']?.toString() ?? '',
        lastFrom: json['lastFrom']?.toString() ?? '',
        at: json['at']?.toString() ?? '',
        count: _asInt(json['count']),
        waiting: json['waiting'] == true,
      );
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
