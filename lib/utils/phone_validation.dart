// This file handles phone number validation logic.
// It is shared across Sign In and Sign Up screens.

class PhoneValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? phoneWithCountryCode;

  const PhoneValidationResult({
    required this.isValid,
    this.errorMessage,
    this.phoneWithCountryCode,
  });
}

class PhoneValidator {
  static const String errorText = 'Please enter a valid phone number';

  // We assume +1 (US) is the default country code
  static const String countryCode = '+1';

  static PhoneValidationResult validate(String input) {
    // Remove spaces and extra characters
    final String cleaned =
        input.replaceAll(RegExp(r'[^0-9]'), '').trim();

    if (cleaned.isEmpty) {
      return const PhoneValidationResult(
        isValid: false,
        errorMessage: errorText,
      );
    }

    // Phone number must be exactly 10 digits
    if (cleaned.length != 10) {
      return const PhoneValidationResult(
        isValid: false,
        errorMessage: errorText,
      );
    }

    // Simple safety check for invalid starting digits
    if (cleaned.startsWith('0') || cleaned.startsWith('1')) {
      return const PhoneValidationResult(
        isValid: false,
        errorMessage: errorText,
      );
    }

    // Build phone number with country code for Firebase
    final String fullNumber = '$countryCode$cleaned';

    return PhoneValidationResult(
      isValid: true,
      phoneWithCountryCode: fullNumber,
    );
  }
}