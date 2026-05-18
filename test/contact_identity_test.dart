import 'package:flutter_test/flutter_test.dart';
import 'package:mini_golf_tracker/contact_identity.dart';

void main() {
  group('ContactIdentity.normalizeEmail', () {
    test('trims and lowercases email values', () {
      expect(
        ContactIdentity.normalizeEmail('  Player@Example.COM  '),
        'player@example.com',
      );
    });

    test('returns null for empty values', () {
      expect(ContactIdentity.normalizeEmail('   '), isNull);
      expect(ContactIdentity.normalizeEmail(null), isNull);
    });
  });

  group('ContactIdentity.normalizePhoneNumber', () {
    test('removes formatting and preserves a leading plus', () {
      expect(
        ContactIdentity.normalizePhoneNumber(' +1 (555) 123-4567 '),
        '+15551234567',
      );
    });

    test('returns digits only when there is no leading plus', () {
      expect(
        ContactIdentity.normalizePhoneNumber('(555) 123-4567'),
        '5551234567',
      );
    });

    test('returns null for empty values', () {
      expect(ContactIdentity.normalizePhoneNumber('---'), isNull);
      expect(ContactIdentity.normalizePhoneNumber(null), isNull);
    });
  });
}
