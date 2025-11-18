import 'dart:io' show File;
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  FirebaseStorage? _storage;
  StorageService({FirebaseStorage? storage}) : _storage = storage;

  Future<String> uploadFile({
    File? file,
    Uint8List? bytes,
    required String path,
    String? contentType,
  }) async {
    final storage = _storage ?? FirebaseStorage.instance;
    final ref = storage.ref().child(path);
    UploadTask task;
    if (file != null) {
      task = ref.putFile(file, SettableMetadata(contentType: contentType));
    } else if (bytes != null) {
      task = ref.putData(bytes, SettableMetadata(contentType: contentType));
    } else {
      throw ArgumentError('Either file or bytes must be provided');
    }
    final snapshot = await task;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> deleteByUrl(String url) async {
    final storage = _storage ?? FirebaseStorage.instance;
    final ref = storage.refFromURL(url);
    await ref.delete();
  }
}
