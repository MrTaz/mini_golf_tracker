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

    test('returns null for null and empty values', () {
      expect(ContactIdentity.normalizeEmail(null), isNull);
      expect(ContactIdentity.normalizeEmail(''), isNull);
      expect(ContactIdentity.normalizeEmail('   '), isNull);
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

    test('returns null for null and empty values', () {
      expect(ContactIdentity.normalizePhoneNumber(null), isNull);
      expect(ContactIdentity.normalizePhoneNumber('---'), isNull);
    });
  });

  group('ContactIdentity reservation IDs', () {
    test('formats reservation IDs for normalized email values', () {
      expect(
        ContactIdentity.reservationIdForEmail('player@example.com'),
        'email_player@example.com',
      );
    });

    test('formats reservation IDs for normalized phone number values', () {
      expect(
        ContactIdentity.reservationIdForPhoneNumber('+15551234567'),
        'phone_+15551234567',
      );
    });
  });
}
