// Desk and washer journey on a simulator, against a backend on this machine
// (never the live API):
//
//   cd backend && node test/local-api/serve.js     # in-memory DB with demo data
//   cd admin && flutter test integration_test/desk_flow_test.dart \
//     -d <simulator id> --dart-define=API_BASE=http://localhost:5001/api
//
// Lines starting with `SHOT:` mark screens worth a screenshot.
import 'package:car_clean_staff/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> waitFor(WidgetTester tester, Finder finder, {int seconds = 20}) async {
    final end = DateTime.now().add(Duration(seconds: seconds));
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 200));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out waiting for $finder');
  }

  Future<void> settle(WidgetTester tester, [int ms = 900]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester, 600);
    // ignore: avoid_print
    print('SHOT:$name');
    await settle(tester, 2500);
  }

  Future<void> tapOn(WidgetTester tester, Finder all) async {
    try {
      await waitFor(tester, all, seconds: 6);
    } on TestFailure {
      await tester.scrollUntilVisible(all, 250, scrollable: find.byType(Scrollable).hitTestable().first);
    }
    final finder = all.last;
    await tester.ensureVisible(finder);
    await settle(tester, 300);
    await tester.tap(finder, warnIfMissed: false);
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) => tapOn(tester, find.text(text));

  Future<void> type(WidgetTester tester, String label, String value) async {
    final field = find.widgetWithText(TextField, label).last;
    await waitFor(tester, field);
    await tester.ensureVisible(field);
    await tester.enterText(field, value);
    await settle(tester, 300);
  }

  Future<void> signIn(WidgetTester tester, String email, String password) async {
    await waitFor(tester, find.text('Staff sign in'));
    await type(tester, 'Email', email);
    await type(tester, 'Password', password);
    await tapOn(tester, find.widgetWithText(FilledButton, 'Sign in'));
  }

  testWidgets('desk assigns, reprices and answers; washer accepts and reads the chat', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AdminApp());

    // ---- Desk ----
    await signIn(tester, 'desk@example.com', 'desk123');
    await waitFor(tester, find.text('Need a washer'));
    await shot(tester, 'desk_dashboard');

    await tapText(tester, 'Need a washer');
    await waitFor(tester, find.text('No washer yet'));
    await shot(tester, 'desk_bookings_unassigned');
    await tapText(tester, 'Priya Sharma');
    await waitFor(tester, find.text('Assign washer'));
    await shot(tester, 'desk_booking');

    await tapOn(tester, find.byType(DropdownButtonFormField<String>));
    await tapText(tester, 'Ravi Kumar · off shift');
    await tapText(tester, 'Assign washer');
    await waitFor(tester, find.text('Washer assigned'));
    await waitFor(tester, find.text('Ravi Kumar'));

    await tapText(tester, 'Reschedule / edit');
    await type(tester, 'Price', '450');
    await tapText(tester, 'Save changes');
    await waitFor(tester, find.text('₹450'));
    await waitFor(tester, find.text('Price changed from ₹399 to ₹450'));
    await shot(tester, 'desk_booking_edited');

    await tapText(tester, 'Chat');
    await waitFor(tester, find.text('Please come after 4 pm'));
    await type(tester, 'Write to the customer', 'Ravi is on the way at 4:30');
    await settle(tester, 1200);
    await tester.tap(find.byTooltip('Send'));
    await waitFor(tester, find.descendant(of: find.byType(ListView), matching: find.text('Ravi is on the way at 4:30')));
    await shot(tester, 'desk_chat');
    await tester.pageBack();
    await settle(tester);
    await tester.pageBack();
    await settle(tester);

    await tapText(tester, 'More');
    await tapText(tester, 'Log out');

    // ---- Washer ----
    await signIn(tester, 'ravi@example.com', 'ravi123');
    await waitFor(tester, find.text('Today’s jobs'));
    await waitFor(tester, find.text('Priya Sharma'));
    await shot(tester, 'staff_jobs');
    await tapOn(tester, find.byType(Switch));
    await waitFor(tester, find.text('Mark accepted'));
    await tapText(tester, 'Mark accepted');
    await waitFor(tester, find.text('Mark on the way'));
    await shot(tester, 'staff_accepted');

    await tapText(tester, 'Chat');
    await waitFor(tester, find.text('Ravi is on the way at 4:30'));
    await shot(tester, 'staff_chat');
  });
}
