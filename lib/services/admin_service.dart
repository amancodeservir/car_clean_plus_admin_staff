import '../core/api_client.dart';
import '../core/constants.dart';
import '../models/models.dart';

class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  Future<DashboardStats> dashboard(String token) async {
    final data = await _api.request(
      method: 'GET',
      path: AppConstants.dashboard,
      token: token,
    );
    final payload = data['data'];
    if (payload is! Map) {
      throw ApiException('Dashboard was empty', 0);
    }
    return DashboardStats.fromJson(Map<String, dynamic>.from(payload));
  }

  Future<List<LedgerEntry>> transactions(String token) async {
    final data = await _api.request(
      method: 'GET',
      path: AppConstants.transactions,
      token: token,
    );
    return mapList(data['data'], LedgerEntry.fromJson);
  }

  Future<BookingRecord> booking(String token, String id) async {
    final data = await _api.request(
      method: 'GET',
      path: AppConstants.booking(id),
      token: token,
    );
    final payload = data['data'];
    if (payload is! Map) {
      throw ApiException('Booking was empty', 0);
    }
    return BookingRecord.fromJson(Map<String, dynamic>.from(payload));
  }

  Future<List<BookingRecord>> bookings(String token, {String query = ''}) async {
    final data = await _api.request(
      method: 'GET',
      path: '${AppConstants.bookings}$query',
      token: token,
    );
    return mapList(data['data'], BookingRecord.fromJson);
  }

  Future<void> updateStatus(String token, String id, String status) {
    return _api.request(
      method: 'PUT',
      path: AppConstants.bookingStatus(id),
      token: token,
      body: {'status': status},
    );
  }

  Future<void> deleteBooking(String token, String id) {
    return _api.request(
      method: 'DELETE',
      path: AppConstants.booking(id),
      token: token,
    );
  }

  Future<String> createPhoneBooking(
    String token,
    Map<String, dynamic> body,
  ) async {
    final data = await _api.request(
      method: 'POST',
      path: AppConstants.manualBooking,
      token: token,
      body: {'type': 'phone_booking', ...body},
    );
    return data['message']?.toString() ?? 'Phone booking saved';
  }

  Future<String> blockSlot(String token, Map<String, dynamic> body) async {
    final data = await _api.request(
      method: 'POST',
      path: AppConstants.manualBooking,
      token: token,
      body: {'type': 'block_slot', ...body},
    );
    return data['message']?.toString() ?? 'Slot blocked';
  }

  Future<List<StaffAccount>> users(String token) async {
    final data = await _api.request(
      method: 'GET',
      path: AppConstants.users,
      token: token,
    );
    return mapList(data['data'], StaffAccount.fromJson);
  }

  Future<void> updateRole(String token, String id, String role) {
    return _api.request(
      method: 'PUT',
      path: AppConstants.userRole(id),
      token: token,
      body: {'role': role},
    );
  }

  Future<List<ContactMessage>> contacts(String token) async {
    final data = await _api.request(
      method: 'GET',
      path: AppConstants.contacts,
      token: token,
    );
    return mapList(data['data'], ContactMessage.fromJson);
  }

  Future<List<GalleryItem>> gallery(String token) async {
    final data = await _api.request(
      method: 'GET',
      path: AppConstants.galleryAdmin,
      token: token,
    );
    return mapList(data['data'], GalleryItem.fromJson);
  }

  Future<void> createGallery(String token, Map<String, dynamic> body) {
    return _api.request(
      method: 'POST',
      path: AppConstants.gallery,
      token: token,
      body: body,
    );
  }

  Future<void> setGalleryActive(String token, String id, bool active) {
    return _api.request(
      method: 'PUT',
      path: AppConstants.galleryItem(id),
      token: token,
      body: {'isActive': active},
    );
  }

  Future<void> deleteGallery(String token, String id) {
    return _api.request(
      method: 'DELETE',
      path: AppConstants.galleryItem(id),
      token: token,
    );
  }

  Future<FestivalSetting> festival(String token) async {
    final data = await _api.request(
      method: 'GET',
      path: AppConstants.festival,
      token: token,
    );
    final payload = data['data'];
    if (payload is! Map) {
      throw ApiException('Festival settings were empty', 0);
    }
    return FestivalSetting.fromJson(Map<String, dynamic>.from(payload));
  }

  Future<String> assignStaff(String token, String bookingId, String staffId) async {
    final data = await _api.request(
      method: 'PUT',
      path: AppConstants.assignBooking(bookingId),
      token: token,
      body: {'staffId': staffId},
    );
    return data['message']?.toString() ?? 'Assigned';
  }

  /// A washer's jobs for one [date], or every open job outside today and
  /// tomorrow when [upcoming] is true.
  Future<List<BookingRecord>> staffJobs(String token, {String? date, bool upcoming = false}) async {
    final path = upcoming
        ? '${AppConstants.staffJobs}?scope=upcoming'
        : date == null || date.isEmpty
            ? AppConstants.staffJobs
            : '${AppConstants.staffJobs}?date=$date';
    final data = await _api.request(
      method: 'GET',
      path: path,
      token: token,
    );
    return mapList(data['data'], BookingRecord.fromJson);
  }

  Future<void> updateStaffJob(String token, String id, String status) {
    return _api.request(
      method: 'PUT',
      path: AppConstants.staffJobStatus(id),
      token: token,
      body: {'status': status},
    );
  }

  Future<void> updateFestival(String token, FestivalSetting setting) {
    return _api.request(
      method: 'PUT',
      path: AppConstants.festival,
      token: token,
      body: {
        'activeFestival': setting.activeFestival,
        'isOfferActive': setting.isOfferActive,
        'customOfferPrice': setting.customOfferPrice,
        'customDiscount': setting.customDiscount,
      },
    );
  }

  Future<void> post(String token, String path, Map<String, dynamic> body) {
    return _api.request(method: 'POST', path: path, token: token, body: body);
  }

  Future<void> put(String token, String path, Map<String, dynamic> body) {
    return _api.request(method: 'PUT', path: path, token: token, body: body);
  }

  Future<({List<DeskAlert> items, int unread})> notifications(String token) async {
    final data = await _api.request(
      method: 'GET',
      path: AppConstants.notifications,
      token: token,
    );
    return (
      items: mapList(data['data'], DeskAlert.fromJson),
      unread: data['unread'] is num ? (data['unread'] as num).toInt() : 0,
    );
  }

  Future<void> markNotificationsRead(String token) {
    return _api.request(
      method: 'PUT',
      path: '${AppConstants.notifications}/read',
      token: token,
      body: {},
    );
  }

  Future<StaffDaySummary> staffSummary(String token) async {
    final data = await _api.request(
      method: 'GET',
      path: AppConstants.staffSummary,
      token: token,
    );
    final payload = data['data'];
    if (payload is! Map) {
      throw ApiException('Today’s summary was empty', 0);
    }
    return StaffDaySummary.fromJson(Map<String, dynamic>.from(payload));
  }

  /// Washers only, on-shift first is up to the caller.
  Future<List<StaffAccount>> staff(String token) async {
    final data = await _api.request(method: 'GET', path: AppConstants.staffAccount, token: token);
    return mapList(data['data'], StaffAccount.fromJson);
  }

  /// Desk edit: date, slot, price, notes, or mark paid.
  Future<BookingRecord> editBooking(String token, String id, Map<String, dynamic> body) async {
    final data = await _api.request(method: 'PUT', path: AppConstants.booking(id), token: token, body: body);
    return BookingRecord.fromJson(Map<String, dynamic>.from(data['data'] as Map));
  }

  Future<BookingRecord> setStatus(String token, String id, String status, {String reason = ''}) async {
    final data = await _api.request(
      method: 'PUT',
      path: AppConstants.bookingStatus(id),
      token: token,
      body: {'status': status, if (reason.isNotEmpty) 'reason': reason},
    );
    return BookingRecord.fromJson(Map<String, dynamic>.from(data['data'] as Map));
  }

  Future<String> refund(String token, String id, num amount) async {
    final data = await _api.request(
      method: 'PUT',
      path: AppConstants.refundBooking(id),
      token: token,
      body: {'amount': amount},
    );
    return data['message']?.toString() ?? 'Refund recorded';
  }

  Future<List<ChatMessage>> messages(String token, String bookingId) async {
    final data = await _api.request(method: 'GET', path: AppConstants.messages(bookingId), token: token);
    return mapList(data['data'], ChatMessage.fromJson);
  }

  Future<void> sendMessage(String token, String bookingId, String body) {
    return _api.request(method: 'POST', path: AppConstants.messages(bookingId), token: token, body: {'body': body});
  }

  Future<List<InboxThread>> inbox(String token) async {
    final data = await _api.request(method: 'GET', path: AppConstants.inbox, token: token);
    return mapList(data['data'], InboxThread.fromJson);
  }

  /// The catalog price for a phone booking, or null when there is none.
  Future<num?> quote(String token, {required String category, required String service, required String city}) async {
    try {
      final data = await _api.request(
        method: 'POST',
        path: '${AppConstants.catalog}/quote',
        token: token,
        body: {'category': category, 'service': service, 'city': city},
      );
      final payload = data['data'];
      return payload is Map && payload['total'] is num ? payload['total'] as num : null;
    } on ApiException {
      return null;
    }
  }

  Future<Map<String, dynamic>> getMap(String token, String path) async {
    final data = await _api.request(method: 'GET', path: path, token: token);
    return data;
  }
}
