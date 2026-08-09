import 'package:cloud_firestore/cloud_firestore.dart';

class UrlModel {
  final String? id;
  final String name;
  final String url;
  final String description;
  final DateTime createdAt;
  final bool isFavorite;
  final String category;
  final String? username;
  final String? password;

  UrlModel({
    this.id,
    required this.name,
    required this.url,
    required this.description,
    required this.createdAt,
    this.isFavorite = false,
    this.category = 'General',
    this.username,
    this.password,
  });

  bool get hasCredentials =>
      (username != null && username!.isNotEmpty) ||
      (password != null && password!.isNotEmpty);

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'url': url,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'isFavorite': isFavorite,
      'category': category,
      'username': username,
      'password': password,
    };
  }

  factory UrlModel.fromMap(Map<String, dynamic> map, String id) {
    return UrlModel(
      id: id,
      name: map['name'] ?? '',
      url: map['url'] ?? '',
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      isFavorite: map['isFavorite'] ?? false,
      category: map['category'] ?? 'General',
      username: map['username'],
      password: map['password'],
    );
  }

  UrlModel copyWith({
    String? id,
    String? name,
    String? url,
    String? description,
    DateTime? createdAt,
    bool? isFavorite,
    String? category,
    String? username,
    String? password,
  }) {
    return UrlModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      category: category ?? this.category,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }
}
