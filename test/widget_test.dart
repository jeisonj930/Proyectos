import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:control_finca_flutter_web/main.dart';

void main() {
  testWidgets('Muestra el dashboard inicial', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ControlFincaWebApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('San Pedro'), findsOneWidget);
    expect(find.text('Tablero de rotación'), findsOneWidget);
    expect(find.text('Terneras'), findsWidgets);
    expect(find.text('Potreros'), findsWidgets);
  });
}
