class Project {
  String title;
  String description;

  Project({required this.title, required this.description});

  factory Project.fromMap(Map<String, dynamic> map) =>
      Project(title: map['title'] ?? '', description: map['description'] ?? '');

  Map<String, dynamic> toMap() => {'title': title, 'description': description};

  Project copyWith({String? title, String? description}) {
    return Project(
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }
}
