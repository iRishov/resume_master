class Certification {
  String name;
  String organization;
  String year;

  Certification({
    required this.name,
    required this.organization,
    required this.year,
  });

  factory Certification.fromMap(Map<String, dynamic> map) => Certification(
    name: map['name'] ?? '',
    organization: map['organization'] ?? '',
    year: map['year'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'name': name,
    'organization': organization,
    'year': year,
  };

  Certification copyWith({String? name, String? organization, String? year}) {
    return Certification(
      name: name ?? this.name,
      organization: organization ?? this.organization,
      year: year ?? this.year,
    );
  }
}
