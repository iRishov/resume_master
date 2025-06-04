class Education {
  String degree;
  String institution;
  String year;
  String description;

  Education({
    required this.degree,
    required this.institution,
    required this.year,
    required this.description,
  });

  factory Education.fromMap(Map<String, dynamic> map) => Education(
    degree: map['degree'] ?? '',
    institution: map['institution'] ?? '',
    year: map['year'] ?? '',
    description: map['description'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'degree': degree,
    'institution': institution,
    'year': year,
    'description': description,
  };

  Education copyWith({
    String? degree,
    String? institution,
    String? year,
    String? description,
  }) {
    return Education(
      degree: degree ?? this.degree,
      institution: institution ?? this.institution,
      year: year ?? this.year,
      description: description ?? this.description,
    );
  }
}
