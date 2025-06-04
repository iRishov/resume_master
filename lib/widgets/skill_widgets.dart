import 'package:flutter/material.dart';
import 'dart:async'; // Import Timer

// Widget for adding and displaying custom skills
class CustomSkillsSection extends StatefulWidget {
  final List<String> initialSkills;
  final ValueChanged<List<String>> onChanged;

  const CustomSkillsSection({
    Key? key,
    required this.initialSkills,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CustomSkillsSectionState createState() => _CustomSkillsSectionState();
}

class _CustomSkillsSectionState extends State<CustomSkillsSection> {
  late List<String> _customSkills;
  final TextEditingController _newSkillController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _customSkills = List.from(widget.initialSkills);
  }

  void _addSkill() {
    final newSkill = _newSkillController.text.trim();
    if (newSkill.isNotEmpty && !_customSkills.contains(newSkill)) {
      setState(() {
        _customSkills.add(newSkill);
        _newSkillController.clear();
        widget.onChanged(_customSkills);
      });
    }
  }

  void _removeSkill(String skill) {
    setState(() {
      _customSkills.remove(skill);
      widget.onChanged(_customSkills);
    });
  }

  @override
  void dispose() {
    _newSkillController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Skills',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your own custom skills that are not in the predefined list',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _newSkillController,
          decoration: InputDecoration(
            hintText: 'Enter Your Professional skill',
            suffixIcon: IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: _addSkill,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          onSubmitted: (_) => _addSkill(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _customSkills.map((skill) {
                return Chip(
                  label: Text(skill),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _removeSkill(skill),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}

// Widget for the skill search bar
class SkillSearchBar extends StatefulWidget {
  final ValueChanged<String> onChanged;

  const SkillSearchBar({Key? key, required this.onChanged}) : super(key: key);

  @override
  _SkillSearchBarState createState() => _SkillSearchBarState();
}

class _SkillSearchBarState extends State<SkillSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _searchController,
      decoration: InputDecoration(
        hintText: 'Search predefined skills...',
        prefixIcon: const Icon(Icons.search),
        suffixIcon:
            _searchController.text.isNotEmpty
                ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    widget.onChanged('');
                  },
                )
                : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      onChanged: (value) {
        if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          widget.onChanged(value.toLowerCase());
        });
      },
    );
  }
}

// Widget for skill categories filter
class SkillCategoriesFilter extends StatelessWidget {
  final Map<String, List<String>> skillCategories;
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const SkillCategoriesFilter({
    Key? key,
    required this.skillCategories,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            skillCategories.keys.map((category) {
              final isSelected = category == selectedCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      onCategorySelected(category);
                    }
                  },
                  selectedColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color:
                        isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}

// Widget for displaying filtered available skills
class FilteredSkillsDisplay extends StatelessWidget {
  final List<String> filteredSkills;
  final Set<String> selectedSkills;
  final ValueChanged<String> onSkillSelected;

  const FilteredSkillsDisplay({
    Key? key,
    required this.filteredSkills,
    required this.selectedSkills,
    required this.onSkillSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (filteredSkills.isEmpty) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          filteredSkills.map((skill) {
            return FilterChip(
              label: Text(skill),
              selected: selectedSkills.contains(skill),
              onSelected: (selected) {
                if (selected) {
                  onSkillSelected(skill);
                }
              },
              selectedColor: Theme.of(
                context,
              ).colorScheme.primary.withOpacity(0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color:
                    selectedSkills.contains(skill)
                        ? Theme.of(context).colorScheme.primary
                        : Colors.black87,
                fontWeight:
                    selectedSkills.contains(skill)
                        ? FontWeight.bold
                        : FontWeight.normal,
              ),
            );
          }).toList(),
    );
  }
}

// Widget for displaying selected skills
class SelectedSkillsDisplay extends StatelessWidget {
  final Set<String> selectedSkills;
  final ValueChanged<String> onSkillRemoved;

  const SelectedSkillsDisplay({
    Key? key,
    required this.selectedSkills,
    required this.onSkillRemoved,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (selectedSkills.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Selected Skills',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              selectedSkills.map((skill) {
                return Chip(
                  label: Text(skill),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => onSkillRemoved(skill),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.1),
                  labelStyle: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }
}
