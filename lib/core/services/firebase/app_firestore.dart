import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../utils/constants.dart';

/// The Firestore instance every repository must use.
///
/// Do **not** call `FirebaseFirestore.instance` directly: that always targets
/// the database literally named `(default)`, parentheses included. This project
/// stores its data in a named database (see
/// [Constants.firestoreDatabaseId]), so `instance` would fail every call with
/// `NOT_FOUND: The database (default) does not exist`.
FirebaseFirestore get appFirestore => FirebaseFirestore.instanceFor(
  app: Firebase.app(),
  databaseId: Constants.firestoreDatabaseId,
);
