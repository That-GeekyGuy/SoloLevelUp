import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sololevelup/main.dart';

void main() {
  testWidgets('shows the missing-config screen when Supabase is unset', (
    WidgetTester tester,
  ) async {
    // SupabaseConfig reads --dart-define values that are empty in the test
    // runner, so the app should fail safe into _MissingConfigScreen rather
    // than crash trying to reach a Supabase project that isn't configured.
    await tester.pumpWidget(const ProviderScope(child: SoloLevelUpApp()));

    expect(find.text('Supabase isn\'t configured yet'), findsOneWidget);
  });
}
