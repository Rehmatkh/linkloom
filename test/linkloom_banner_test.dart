import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:linkloom/linkloom.dart';

void main() {
  testWidgets('NetPulseBanner renders the child and shows no banner text initially', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NetPulseBanner(
          child: Text('child content'),
        ),
      ),
    );

    expect(find.text('child content'), findsOneWidget);
    expect(find.text("You're offline"), findsNothing);
    expect(find.text('Back online'), findsNothing);
  });

  testWidgets('NetPulseBanner accepts custom messages and colors', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NetPulseBanner(
          offlineMessage: 'Offline now',
          backOnlineMessage: 'Back online now',
          offlineColor: Colors.amber,
          backOnlineColor: Colors.purple,
          child: Text('child content'),
        ),
      ),
    );

    final banner = tester.widget<NetPulseBanner>(find.byType(NetPulseBanner));
    expect(banner.offlineMessage, 'Offline now');
    expect(banner.backOnlineMessage, 'Back online now');
    expect(banner.offlineColor, Colors.amber);
    expect(banner.backOnlineColor, Colors.purple);
    expect(find.text('Offline now'), findsNothing);
    expect(find.text('Back online now'), findsNothing);
  });
}
