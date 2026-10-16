import 'package:car_clean_staff/models/models.dart';
import 'package:car_clean_staff/theme/desk_theme.dart';
import 'package:flutter_test/flutter_test.dart';

BookingRecord booking(Map<String, dynamic> extra) => BookingRecord.fromJson({
      '_id': 'b1',
      'service': 'Basic Wash',
      'finalPrice': 500,
      'status': 'confirmed',
      'customerDetails': {'fullName': 'Asha', 'mobile': '9876543210'},
      ...extra,
    });

void main() {
  test('rupees groups the Indian way', () {
    expect(rupees(0), '₹0');
    expect(rupees(999), '₹999');
    expect(rupees(1500), '₹1,500');
    expect(rupees(123456), '₹1,23,456');
    expect(rupees(-2500), '-₹2,500');
  });

  test('role labels', () {
    expect(roleLabel('staff'), 'Washer');
    expect(roleLabel('superadmin'), 'Super admin');
  });

  test('unpaid booking has nothing to refund', () {
    final row = booking({'paymentStatus': 'pending'});
    expect(row.isPaid, isFalse);
    expect(row.refundable, 0);
    expect(row.due, 500);
  });

  test('paid booking can refund the price, and the case of the status does not matter', () {
    final row = booking({'paymentStatus': 'Paid'});
    expect(row.isPaid, isTrue);
    expect(row.refundable, 500);
  });

  test('part collected at the car can be refunded', () {
    final row = booking({'collectedCash': 200, 'paymentStatus': 'pending'});
    expect(row.refundable, 200);
    expect(row.due, 300);
  });

  test('refunded booking cannot refund again', () {
    final row = booking({'paymentStatus': 'refunded', 'refundAmount': 500});
    expect(row.refundable, 0);
    expect(row.isRefunded, isTrue);
  });

  test('assigned staff as a bare id or populated object', () {
    expect(booking({'assignedStaff': 's1'}).assignedStaffId, 's1');
    expect(booking({'assignedStaff': {'_id': 's2', 'name': 'Ravi'}}).assignedStaffName, 'Ravi');
    expect(booking({}).isAssigned, isFalse);
  });

  test('timeline steps are read', () {
    final row = booking({
      'timeline': [
        {'status': 'confirmed', 'at': '2026-10-16T05:00:00Z', 'byName': 'Desk', 'note': 'Phone booking'},
      ],
    });
    expect(row.timeline.single.note, 'Phone booking');
  });

  test('alert keeps its booking id', () {
    final alert = DeskAlert.fromJson({'_id': 'a', 'title': 'New customer', 'body': '', 'booking': 'b9'});
    expect(alert.bookingId, 'b9');
  });

  test('inbox thread waiting flag', () {
    final thread = InboxThread.fromJson({'booking': 'b1', 'customer': 'Asha', 'waiting': true, 'count': 3});
    expect(thread.waiting, isTrue);
    expect(thread.count, 3);
  });
}
