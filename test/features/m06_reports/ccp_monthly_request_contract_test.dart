import 'package:flutter_test/flutter_test.dart';
import 'package:haccp_pilot/features/m06_reports/screens/ccp2_preview_screen.dart';
import 'package:haccp_pilot/features/m06_reports/screens/ccp3_preview_screen.dart';

void main() {
  group('CCP monthly request contract', () {
    test('CCP3 request equality ignores day within the same month', () {
      final left = Ccp3ReportRequest(date: DateTime(2026, 2, 1));
      final right = Ccp3ReportRequest(date: DateTime(2026, 2, 28));

      expect(left, equals(right));
      expect(left.hashCode, equals(right.hashCode));
    });

    test('CCP3 request differs when forceRegenerate differs', () {
      final left = Ccp3ReportRequest(date: DateTime(2026, 2, 15));
      final right = Ccp3ReportRequest(
        date: DateTime(2026, 2, 20),
        forceRegenerate: true,
      );

      expect(left == right, isFalse);
    });

    test('CCP2 request equality ignores day within the same month', () {
      final left = Ccp2ReportRequest(date: DateTime(2026, 2, 2));
      final right = Ccp2ReportRequest(date: DateTime(2026, 2, 22));

      expect(left, equals(right));
      expect(left.hashCode, equals(right.hashCode));
    });
  });
}
