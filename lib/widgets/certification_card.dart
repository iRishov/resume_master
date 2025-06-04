import 'package:flutter/material.dart';
import '../models/certification.dart';

class CertificationCard extends StatelessWidget {
  final Certification certification;
  final ValueChanged<Certification> onChanged;
  final VoidCallback onDelete;
  final bool autofocus;

  const CertificationCard({
    Key? key,
    required this.certification,
    required this.onChanged,
    required this.onDelete,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  certification.name.isNotEmpty
                      ? certification.name
                      : 'Certification',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: certification.name,
              decoration: const InputDecoration(
                labelText: 'Certification Name',
                hintText: 'Enter certification name',
                prefixIcon: Icon(Icons.card_membership_outlined),
              ),
              autofocus: autofocus,
              onChanged:
                  (value) => onChanged(certification.copyWith(name: value)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: certification.organization,
              decoration: const InputDecoration(
                labelText: 'Organization',
                hintText: 'Enter organization name',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              onChanged:
                  (value) =>
                      onChanged(certification.copyWith(organization: value)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: certification.year,
              decoration: const InputDecoration(
                labelText: 'Year',
                hintText: 'e.g., 2022',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              onChanged:
                  (value) => onChanged(certification.copyWith(year: value)),
            ),
          ],
        ),
      ),
    );
  }
}
