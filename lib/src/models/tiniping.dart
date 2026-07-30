class Tiniping {
  const Tiniping({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.type,
    required this.releaseVersion,
    required this.description,
    required this.extraFields,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String type;
  final String releaseVersion;
  final String description;
  final Map<String, String> extraFields;
}
