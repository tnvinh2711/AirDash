import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Creates a [LazyDatabase] connection for the application.
///
/// The database file is stored in the application documents directory
/// with the name `flux.sqlite`.
///
/// Uses [NativeDatabase.createInBackground] for thread-safe operations.
LazyDatabase openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'flux.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
