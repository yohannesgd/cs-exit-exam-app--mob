class Resource {
  final String title;
  final String category;
  final String description;
  final String link;
  final String type;

  Resource({required this.title, required this.category, required this.description, required this.link, required this.type});
  factory Resource.fromJson(Map<String, dynamic> json) {
    return Resource(
      title: json['title'],
      category: json['category'],
      description: json['description'],
      link: json['link'],
      type: json['type'],
    );
  }
}