import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/url_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String collectionPath = 'urls';

  FirestoreService() {
    // Enable offline persistence (Done automatically by Firebase in Flutter, 
    // but can be explicitly configured if needed).
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  // Stream of URLs
  Stream<List<UrlModel>> getUrls() {
    return _db
        .collection(collectionPath)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UrlModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Create
  Future<void> addUrl(UrlModel url) async {
    await _db.collection(collectionPath).add(url.toMap());
  }

  // Update
  Future<void> updateUrl(UrlModel url) async {
    if (url.id != null) {
      await _db.collection(collectionPath).doc(url.id).update(url.toMap());
    }
  }

  // Delete
  Future<void> deleteUrl(String id) async {
    await _db.collection(collectionPath).doc(id).delete();
  }
}
