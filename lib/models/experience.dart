class Experience {
  String jobTitle;
  String company;
  String duration;
  String description;

  Experience({
    required this.jobTitle,
    required this.company,
    required this.duration,
    required this.description,
  });

  factory Experience.fromMap(Map<String, dynamic> map) => Experience(
    jobTitle: map['jobTitle'] ?? '',
    company: map['company'] ?? '',
    duration: map['duration'] ?? '',
    description: map['description'] ?? '',
  );

  Map<String, dynamic> toMap() => {
    'jobTitle': jobTitle,
    'company': company,
    'duration': duration,
    'description': description,
  };

  Experience copyWith({
    String? jobTitle,
    String? company,
    String? duration,
    String? description,
  }) {
    return Experience(
      jobTitle: jobTitle ?? this.jobTitle,
      company: company ?? this.company,
      duration: duration ?? this.duration,
      description: description ?? this.description,
    );
  }
}
