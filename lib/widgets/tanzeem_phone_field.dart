import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';

class TanzeemPhoneField extends StatelessWidget {
  final String? initialValue;
  final bool required;
  final ValueChanged<String?> onChanged;

  const TanzeemPhoneField({
    super.key,
    this.initialValue,
    this.required = false,
    required this.onChanged,
  });

  static const Color tanzeemGreen = Color(0xFF0B5F4A);
  static const Color tanzeemMuted = Color(0xFF6F7D77);

  @override
  Widget build(BuildContext context) {
    final PhoneNumber startingValue;

    if (initialValue != null && initialValue!.trim().isNotEmpty) {
      startingValue = PhoneNumber.parse(initialValue!);
    } else {
      startingValue = PhoneNumber.parse('+961');
    }

    return PhoneFormField(
      initialValue: startingValue,

      countrySelectorNavigator:
          const CountrySelectorNavigator.draggableBottomSheet(),

      isCountrySelectionEnabled: true,
      isCountryButtonPersistent: true,

      countryButtonStyle: const CountryButtonStyle(
        showDialCode: true,
        showFlag: true,
        showIsoCode: false,
        flagSize: 18,
      ),

      decoration: InputDecoration(
        labelText: required ? 'Phone number' : 'Phone number (optional)',
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: tanzeemMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8ECEA)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE8ECEA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: tanzeemGreen, width: 1.4),
        ),
      ),

      validator: required
          ? PhoneValidator.compose([
              PhoneValidator.required(context),
              PhoneValidator.valid(context),
            ])
          : PhoneValidator.valid(context),

      onChanged: (phone) {
        if (phone == null || phone.nsn.trim().isEmpty) {
          onChanged(null);
          return;
        }

        onChanged(phone.international);
      },
    );
  }
}
