import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/firestore_service.dart';
import '../models/url_model.dart';

final firestoreServiceProvider = Provider((ref) => FirestoreService());

final urlsStreamProvider = StreamProvider<List<UrlModel>>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return service.getUrls();
});
