import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/routine.dart';

class RoutineService {
  FirebaseFirestore? _db;
  RoutineService({FirebaseFirestore? firestore}) : _db = firestore;

  FirebaseFirestore get _firestore => _db ??= FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('routines');

  Future<List<Routine>> fetchForUser(String uid) async {
    try {
      final snap = await _col
          .where('uid', isEqualTo: uid)
          .orderBy('date')
          .get();
      return snap.docs.map((d) => Routine.fromDoc(d)).toList();
    } on FirebaseException catch (e) {
      // Graceful fallback if a composite index is missing for (uid ==, orderBy date)
      // Error code is usually 'failed-precondition' with message mentioning an index.
      final msg = e.message ?? '';
      final looksLikeMissingIndex =
          e.code.toLowerCase() == 'failed-precondition' &&
          msg.toLowerCase().contains('index');
      if (looksLikeMissingIndex) {
        final snap = await _col.where('uid', isEqualTo: uid).get();
        final list = snap.docs.map((d) => Routine.fromDoc(d)).toList();
        list.sort((a, b) => a.date.compareTo(b.date));
        return list;
      }
      rethrow;
    }
  }

  Future<Routine> create(Routine data) async {
    final now = Timestamp.now();
    final doc = await _col.add({
      ...data.toMap(),
      'createdAt': now,
      'updatedAt': now,
    });
    final saved = await doc.get();
    return Routine.fromDoc(saved);
  }

  Future<Routine> update(Routine data) async {
    final ref = _col.doc(data.id);
    await ref.update({...data.toMap(), 'updatedAt': Timestamp.now()});
    final snap = await ref.get();
    return Routine.fromDoc(snap);
  }

  Future<void> delete(String id) async {
    await _col.doc(id).delete();
  }

  Future<Routine> markComplete(String id, {DateTime? at}) async {
    final ref = _col.doc(id);
    final ts = Timestamp.fromDate(at ?? DateTime.now());
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>;
      final completed =
          (data['completedDates'] as List?)?.cast<Timestamp>() ?? [];
      completed.add(ts);
      data['completedDates'] = completed;
      data['status'] = 'completed';
      data['updatedAt'] = Timestamp.now();
      tx.update(ref, data);
    });
    final updated = await ref.get();
    return Routine.fromDoc(updated);
  }

  Future<Routine> unmarkComplete(String id, {required DateTime at}) async {
    final ref = _col.doc(id);
    final ts = Timestamp.fromDate(at);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>;
      final completed =
          (data['completedDates'] as List?)?.cast<dynamic>() ?? [];
      final filtered = completed.where((e) {
        final t = (e is Timestamp)
            ? e
            : (e is Map && e['seconds'] is int)
            ? Timestamp(e['seconds'] as int, (e['nanoseconds'] as int?) ?? 0)
            : null;
        if (t == null) return true;
        return t.toDate().millisecondsSinceEpoch !=
            ts.toDate().millisecondsSinceEpoch;
      }).toList();
      data['completedDates'] = filtered;
      // If no completions remain, set status back to pending
      if (filtered.isEmpty) {
        data['status'] = 'pending';
      }
      data['updatedAt'] = Timestamp.now();
      tx.update(ref, data);
    });
    final updated = await ref.get();
    return Routine.fromDoc(updated);
  }

  Future<Routine> unmarkLastComplete(String id) async {
    final ref = _col.doc(id);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() as Map<String, dynamic>;
      final completedRaw =
          (data['completedDates'] as List?)?.cast<dynamic>() ?? [];
      if (completedRaw.isEmpty) return; // nothing to undo
      // Convert to timestamps and sort descending by time
      final completed = completedRaw
          .map<Timestamp?>(
            (e) => e is Timestamp
                ? e
                : (e is Map && e['seconds'] is int)
                ? Timestamp(
                    e['seconds'] as int,
                    (e['nanoseconds'] as int?) ?? 0,
                  )
                : null,
          )
          .whereType<Timestamp>()
          .toList();
      if (completed.isEmpty) return;
      completed.sort((a, b) => b.toDate().compareTo(a.toDate()));
      final latest = completed.first;
      // Remove one instance equal to latest
      bool removed = false;
      final filtered = completedRaw.where((e) {
        if (removed) return true;
        Timestamp? t;
        if (e is Timestamp) {
          t = e;
        } else if (e is Map && e['seconds'] is int) {
          t = Timestamp(e['seconds'] as int, (e['nanoseconds'] as int?) ?? 0);
        }
        if (t != null &&
            t.toDate().millisecondsSinceEpoch ==
                latest.toDate().millisecondsSinceEpoch) {
          removed = true;
          return false;
        }
        return true;
      }).toList();
      data['completedDates'] = filtered;
      if ((filtered).isEmpty) {
        data['status'] = 'pending';
      }
      data['updatedAt'] = Timestamp.now();
      tx.update(ref, data);
    });
    final updated = await ref.get();
    return Routine.fromDoc(updated);
  }
}
