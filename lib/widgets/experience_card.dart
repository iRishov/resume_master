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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                experience.jobTitle.isNotEmpty
                    ? experience.jobTitle
                    : 'Experience',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: Colors.red,
                size: 20,
              ),
              onPressed: onDelete,
              tooltip: 'Delete',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: experience.jobTitle,
          decoration: const InputDecoration(
            labelText: 'Job Title',
            hintText: 'Enter your job title',
            prefixIcon: Icon(Icons.work_outline),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          autofocus: autofocus,
          onChanged: (value) => onChanged(experience.copyWith(jobTitle: value)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: experience.company,
          decoration: const InputDecoration(
            labelText: 'Company',
            hintText: 'Enter company name',
            prefixIcon: Icon(Icons.business_outlined),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) => onChanged(experience.copyWith(company: value)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: experience.duration,
          decoration: const InputDecoration(
            labelText: 'Duration',
            hintText: 'e.g., Jan 2020 – Present',
            prefixIcon: Icon(Icons.calendar_today_outlined),
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onChanged: (value) => onChanged(experience.copyWith(duration: value)),
        ),
        const SizedBox(height: 12),
        TextFormField(
          initialValue: experience.description,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Describe your responsibilities and achievements',
            prefixIcon: Icon(Icons.description_outlined),
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          maxLines: 4,
          onChanged:
              (value) => onChanged(experience.copyWith(description: value)),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
