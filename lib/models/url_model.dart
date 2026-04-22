import 'package:cloud_firestore/cloud_firestore.dart';

class UrlModel {
  final String? id;
  final String name;
  final String url;
  final String description;
  final DateTime createdAt;

  UrlModel({
    this.id,
    required this.name,
    required this.url,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory UrlModel.fromMap(Map<String, dynamic> map, String id) {
    return UrlModel(
      id: id,
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  UrlModel copyWith({
    String? id,
    String? name,
    String? url,
    String? description,
    DateTime? createdAt,
  }) {
    return UrlModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
