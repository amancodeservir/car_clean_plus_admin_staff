import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:car_clean_admin/main.dart';

void main() {
  testWidgets('shows admin sign in when logged out', (WidgetTester tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const AdminApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(find.text('Car Clean Admin'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
