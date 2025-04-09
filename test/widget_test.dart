//import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:homefinder/main.dart';
import 'package:homefinder/welcom_page.dart';
import 'package:homefinder/login_page.dart';

void main() {
  testWidgets('Affiche WelcomePage uniquement lors du premier lancement', (WidgetTester tester) async {
    // Simule le premier lancement de l'application
    SharedPreferences.setMockInitialValues({'firstLaunch': true});

    await tester.pumpWidget(MyApp());

    // Vérifie que WelcomePage est affichée
    expect(find.byType(WelcomePage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  testWidgets('Affiche LoginPage après le premier lancement', (WidgetTester tester) async {
    // Simule les lancements suivants de l'application
    SharedPreferences.setMockInitialValues({'firstLaunch': false});

    await tester.pumpWidget(MyApp());

    // Vérifie que LoginPage est affichée
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(WelcomePage), findsNothing);
  });
}
