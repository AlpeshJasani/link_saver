class LinkModel {
  String title;
  String url;

  LinkModel({required this.title, required this.url});

  // Convert to and from JSON for storage
  Map<String, dynamic> toJson() => {'title': title, 'url': url};
  factory LinkModel.fromJson(Map<String, dynamic> json) =>
      LinkModel(title: json['title'], url: json['url']);
}
