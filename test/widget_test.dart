import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:timetable/widgets/day_tabs.dart';

void main() {
  testWidgets('DayTabs highlights the selected day and reports taps',
      (WidgetTester tester) async {
    int selected = 1;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return DayTabs(
                selectedDay: selected,
                todayDayOfWeek: 1,
                onDaySelected: (day) => setState(() => selected = day),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Mon'), findsOneWidget);
    expect(find.text('Sun'), findsOneWidget);

    await tester.tap(find.text('Wed'));
    await tester.pump();

    expect(selected, 3);
  });
}
