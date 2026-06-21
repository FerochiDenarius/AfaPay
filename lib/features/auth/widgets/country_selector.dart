import 'package:flutter/material.dart';

import '../models/country.dart';

class CountrySelector extends StatelessWidget {
  const CountrySelector({
    super.key,
    required this.selectedCountry,
    required this.onSelected,
  });

  final Country selectedCountry;
  final ValueChanged<Country> onSelected;

  static const _muted = Color(0xFFA9ABB2);

  Future<void> _showCountryPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF080F1C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _CountryPickerSheet(),
    );
    if (selected != null) onSelected(selected);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Country',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: () => _showCountryPicker(context),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            decoration: BoxDecoration(
              color: const Color(0xFF0B111D).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF303541)),
            ),
            child: Row(
              children: [
                const Icon(Icons.language_rounded, color: _muted, size: 27),
                const SizedBox(width: 16),
                Text(
                  selectedCountry.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    selectedCountry.displayName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _muted,
                  size: 29,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CountryPickerSheet extends StatefulWidget {
  const _CountryPickerSheet();

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final countries = supportedCountries.where((country) {
      final search = query.toLowerCase();
      return country.name.toLowerCase().contains(search) ||
          country.dialCode.contains(search);
    }).toList();

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          14,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.62,
          child: Column(
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF555B66),
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Select Country',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              TextField(
                autofocus: true,
                onChanged: (value) => setState(() => query = value),
                decoration: const InputDecoration(
                  hintText: 'Search country or code',
                  prefixIcon: Icon(Icons.search_rounded),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: countries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final country = countries[index];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      leading: Text(
                        country.flag,
                        style: const TextStyle(fontSize: 27),
                      ),
                      title: Text(country.name),
                      trailing: Text(
                        country.dialCode,
                        style: const TextStyle(color: Color(0xFFF5B81F)),
                      ),
                      onTap: () => Navigator.pop(context, country),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
