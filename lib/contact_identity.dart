class ContactIdentity {
  const ContactIdentity._();

  static String? normalizeEmail(String? email) {
    final normalized = email?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  static String? normalizePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null) return null;

    final trimmed = phoneNumber.trim();
    if (trimmed.isEmpty) return null;

    final hasLeadingPlus = trimmed.startsWith('+');
    final digitsOnly = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (digitsOnly.isEmpty) return null;

    return hasLeadingPlus ? '+$digitsOnly' : digitsOnly;
  }

  static String reservationIdForEmail(String normalizedEmail) {
    return 'email_$normalizedEmail';
  }

  static String reservationIdForPhoneNumber(String normalizedPhoneNumber) {
    return 'phone_$normalizedPhoneNumber';
  }
}
