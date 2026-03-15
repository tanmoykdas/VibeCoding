import 'package:flutter_test/flutter_test.dart';
import 'package:moneyco/core/input_sanitizer.dart';
import 'package:moneyco/core/utils.dart';

void main() {
  group('Moneyco utilities', () {
    test('currency formatting uses taka symbol', () {
      expect(AppUtils.formatCurrency(1200), '৳1,200.00');
    });

    test('sanitizer trims and limits text', () {
      final value = InputSanitizer.sanitizeText(
        '  hello   <world>  ',
        maxLength: 12,
      );

      expect(value, 'hello ‹world');
    });
  });
}
