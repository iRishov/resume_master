import 'package:flutter/material.dart';
import '../models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final ValueChanged<Project> onChanged;
  final VoidCallback onDelete;
  final bool autofocus;

  const ProjectCard({
    Key? key,
    required this.project,
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
                  project.title.isNotEmpty ? project.title : 'Project',
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
              initialValue: project.title,
              decoration: const InputDecoration(
                labelText: 'Project Title',
                hintText: 'Enter project title',
                prefixIcon: Icon(Icons.code_outlined),
              ),
              autofocus: autofocus,
              onChanged: (value) => onChanged(project.copyWith(title: value)),
            ),
            const SizedBox(height: 14),
            TextFormField(
              initialValue: project.description,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Describe your project and your role',
                prefixIcon: Icon(Icons.description_outlined),
              ),
              maxLines: 4,
              onChanged:
                  (value) => onChanged(project.copyWith(description: value)),
            ),
          ],
        ),
      ),
    );
  }
}
