import 'package:flutter/material.dart';
import '../models/experience.dart';

class ExperienceCard extends StatelessWidget {
  final Experience experience;
  final ValueChanged<Experience> onChanged;
  final VoidCallback onDelete;
  final bool autofocus;

  const ExperienceCard({
    Key? key,
    required this.experience,
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
                  experience.jobTitle.isNotEmpty
                      ? experience.jobTitle
                      : 'Experience',
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
              initialValue: experience.jobTitle,
              decoration: const InputDecoration(
                labelText: 'Job Title',
                hintText: 'Enter your job title',
                prefixIcon: Icon(Icons.work_outline),
              ),
              autofocus: autofocus,
              onChanged:
                  (value) => onChanged(experience.copyWith(jobTitle: value)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: experience.company,
              decoration: const InputDecoration(
                labelText: 'Company',
                hintText: 'Enter company name',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              onChanged:
                  (value) => onChanged(experience.copyWith(company: value)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: experience.duration,
              decoration: const InputDecoration(
                labelText: 'Duration',
                hintText: 'e.g., Jan 2020 – Present',
                prefixIcon: Icon(Icons.calendar_today_outlined),
              ),
              onChanged:
                  (value) => onChanged(experience.copyWith(duration: value)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: experience.description,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your responsibilities and achievements',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 4,
              onChanged:
                  (value) => onChanged(experience.copyWith(description: value)),
            ),
          ],
        ),
      ),
    );
  }
}
