import 'package:flutter/material.dart';
import '../models/education.dart';

class EducationCard extends StatelessWidget {
  final Education education;
  final ValueChanged<Education> onChanged;
  final VoidCallback onDelete;
  final bool autofocus;

  const EducationCard({
    Key? key,
    required this.education,
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
                  education.degree.isNotEmpty ? education.degree : 'Education',
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
              initialValue: education.degree,
              decoration: const InputDecoration(
                labelText: 'Degree',
                hintText: 'Enter your degree',
                prefixIcon: Icon(Icons.school_outlined),
              ),
              autofocus: autofocus,
              onChanged:
                  (value) => onChanged(education.copyWith(degree: value)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: education.institution,
              decoration: const InputDecoration(
                labelText: 'Institution',
                hintText: 'Enter institution name',
                prefixIcon: Icon(Icons.account_balance_outlined),
              ),
              onChanged:
                  (value) => onChanged(education.copyWith(institution: value)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: education.year,
              decoration: const InputDecoration(
                labelText: 'Year',
                hintText: 'e.g., 2018 - 2022',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              onChanged: (value) => onChanged(education.copyWith(year: value)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: education.description,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your education and achievements',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 4,
              onChanged:
                  (value) => onChanged(education.copyWith(description: value)),
            ),
          ],
        ),
      ),
    );
  }
}
