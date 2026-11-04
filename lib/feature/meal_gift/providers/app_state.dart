import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../../../core/utils/user_filter.dart';
import '../../../core/services/firebase/app_firestore.dart';
import '../../../core/services/notifications/push_sender.dart';
import '../../admin/controller/admin_notify_controller.dart';
import '../models/models.dart';
import 'package:uuid/uuid.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  bool _isAdmin = false;
  bool _isInitialized = false;

  User? get currentUser {
    if (_currentUser != null) return _currentUser;
    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (fbUser != null) {
      final match = _users.cast<User?>().firstWhere(
        (u) => u?.id == fbUser.uid || (u?.email != null && u?.email == fbUser.email),
        orElse: () => null,
      );
      if (match != null) {
        _currentUser = match;
        return match;
      }
      final name = (fbUser.displayName?.isNotEmpty == true)
          ? fbUser.displayName!
          : (fbUser.email?.isNotEmpty == true)
              ? fbUser.email!.split('@').first
              : 'User';
      final newUser = User(
        id: fbUser.uid,
        name: name,
        role: 'Staff',
        email: fbUser.email,
        photoUrl: fbUser.photoURL,
      );
      _currentUser = newUser;
      return newUser;
    }
    return null;
  }
  bool get isAdmin => _isAdmin;
  bool get isInitialized => _isInitialized;

  final List<User> _users = [];
  List<User> get allUsers {
    final seen = <String>{};
    return _users
        .where((u) =>
            u.id.isNotEmpty &&
            !UserFilter.isExcluded(uid: u.id, name: u.name, email: u.email) &&
            seen.add(u.id))
        .toList();
  }

  final List<BaseEvent> _events = [];
  List<BaseEvent> get events => _events;

  FirebaseFirestore get _firestore => appFirestore;

  AppState() {
    _initFirebaseAndPrefs();
  }

  Future<void> _initFirebaseAndPrefs() async {
    await _loadStateFromPrefs();

    // Auto-sync any locally saved data to Firestore (excluding removed test accounts)
    for (var u in _users) {
      if (UserFilter.isExcluded(uid: u.id, name: u.name, email: u.email)) continue;
      try {
        await _firestore.collection('users').doc(u.id).set(u.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Sync user to Firestore error: $e');
      }
    }
    for (var ev in _events) {
      try {
        await _firestore.collection('events').doc(ev.id).set(ev.toJson());
      } catch (e) {
        debugPrint('Sync event to Firestore error: $e');
      }
    }

    await fetchFromFirestore();

    // Listen to Firestore real-time updates for Users
    _firestore.collection('users').snapshots().listen((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        _users.clear();
        for (var doc in snapshot.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          if ((data['id'] as String?)?.isEmpty ?? true) {
            data['id'] = doc.id;
          }
          final user = User.fromJson(data);
          if (user.id.isNotEmpty &&
              !UserFilter.isExcluded(
                uid: user.id,
                name: user.name,
                email: user.email,
              )) {
            _users.add(user);
          }
        }
        _saveUsersToPrefs();
        notifyListeners();
      }
    }, onError: (e) {
      debugPrint('Firestore users listener error: $e');
    });

    // Listen to Firestore real-time updates for Events
    _firestore.collection('events').snapshots().listen((snapshot) {
      _events.clear();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        _events.add(BaseEvent.fromJson(data));
      }
      _saveEventsToPrefs();
      notifyListeners();
    }, onError: (e) {
      debugPrint('Firestore events listener error: $e');
    });

    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (fbUser != null && _currentUser == null && !_isAdmin) {
      final match = _users.cast<User?>().firstWhere(
        (u) => u?.id == fbUser.uid || (u?.email != null && u?.email == fbUser.email),
        orElse: () => null,
      );
      if (match != null) {
        _currentUser = match;
      } else {
        final name = fbUser.displayName?.isNotEmpty == true
            ? fbUser.displayName!
            : fbUser.email?.isNotEmpty == true
                ? fbUser.email!.split('@').first
                : 'User';
        final newUser = User(
          id: fbUser.uid,
          name: name,
          role: 'Staff',
          email: fbUser.email,
          photoUrl: fbUser.photoURL,
        );
        _users.add(newUser);
        _currentUser = newUser;
        _saveUsersToPrefs();
        try {
          await _firestore.collection('users').doc(newUser.id).set(newUser.toJson(), SetOptions(merge: true));
        } catch (e) {
          debugPrint('Sync current auth user error: $e');
        }
      }
    }

    _isInitialized = true;
    notifyListeners();
  }

  Future<void> fetchFromFirestore() async {
    try {
      final usersSnap = await _firestore.collection('users').get();
      if (usersSnap.docs.isNotEmpty) {
        _users.clear();
        for (var doc in usersSnap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          if ((data['id'] as String?)?.isEmpty ?? true) {
            data['id'] = doc.id;
          }
          final user = User.fromJson(data);
          if (user.id.isNotEmpty &&
              !UserFilter.isExcluded(
                uid: user.id,
                name: user.name,
                email: user.email,
              )) {
            _users.add(user);
          }
        }
        await _saveUsersToPrefs();
      }

      final eventsSnap = await _firestore.collection('events').get();
      if (eventsSnap.docs.isNotEmpty) {
        _events.clear();
        for (var doc in eventsSnap.docs) {
          _events.add(BaseEvent.fromJson(doc.data()));
        }
        await _saveEventsToPrefs();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Firestore fetch error: $e');
    }
  }

  Future<void> _loadStateFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();

    final usersJson = prefs.getStringList('app_users');
    if (usersJson != null && usersJson.isNotEmpty) {
      _users.clear();
      for (var str in usersJson) {
        final map = jsonDecode(str);
        final u = User.fromJson(map);
        if (u.id.isNotEmpty &&
            !UserFilter.isExcluded(
              uid: u.id,
              name: u.name,
              email: u.email,
            )) {
          _users.add(u);
        }
      }
      // Re-save so excluded users are purged from device SharedPreferences
      await _saveUsersToPrefs();
    }

    final eventsJson = prefs.getStringList('app_events');
    if (eventsJson != null && eventsJson.isNotEmpty) {
      _events.clear();
      for (var str in eventsJson) {
        if (str.isNotEmpty) {
          final map = jsonDecode(str);
          _events.add(BaseEvent.fromJson(map));
        }
      }
    }

    final currentUserId = prefs.getString('current_user_id');
    if (currentUserId != null && currentUserId.isNotEmpty) {
      for (var u in _users) {
        if (u.id == currentUserId) {
          _currentUser = u;
          break;
        }
      }
    }
  }

  Future<void> _saveUsersToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> usersJson = _users.map((u) => jsonEncode(u.toJson())).toList();
    await prefs.setStringList('app_users', usersJson);
  }

  Future<void> _saveEventsToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> eventsJson = _events.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList('app_events', eventsJson);
  }

  Future<void> loginWithName(String inputName, {String? email, String? photoUrl, String? uid}) async {
    final trimmed = inputName.trim();
    if (trimmed.isEmpty) return;

    User? existingUser;
    for (var u in _users) {
      if ((uid != null && u.id == uid) ||
          (email != null && u.email != null && u.email!.toLowerCase() == email.toLowerCase()) ||
          u.name.toLowerCase() == trimmed.toLowerCase()) {
        existingUser = u;
        break;
      }
    }

    if (existingUser != null) {
      _currentUser = existingUser;
    } else {
      final newUser = User(
        id: uid ?? const Uuid().v4(),
        name: trimmed,
        role: 'Staff',
        email: email,
        photoUrl: photoUrl,
      );
      _users.add(newUser);
      _currentUser = newUser;
      await _saveUsersToPrefs();
      try {
        await _firestore.collection('users').doc(newUser.id).set(newUser.toJson(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore error: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_user_id', _currentUser!.id);

    _isAdmin = false;
    notifyListeners();
  }

  Future<void> deleteUser(String userId) async {
    _users.removeWhere((u) => u.id == userId);
    await _saveUsersToPrefs();
    try {
      await _firestore.collection('users').doc(userId).delete();
    } catch (e) {
      debugPrint('Firestore delete user error: $e');
    }
    notifyListeners();
  }

  Future<void> loginAsAdmin() async {
    _isAdmin = true;
    _currentUser = null;
    notifyListeners();
  }

  Future<void> logoutAdmin() async {
    _isAdmin = false;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_user_id');
    _currentUser = null;
    _isAdmin = false;
    notifyListeners();
  }

  Future<void> addNewUser(String name, {String? email}) async {
    final newUser = User(
      id: const Uuid().v4(),
      name: name,
      role: 'Staff',
      email: email,
    );
    _users.add(newUser);
    await _saveUsersToPrefs();
    try {
      await _firestore.collection('users').doc(newUser.id).set(newUser.toJson(), SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore error: $e');
    }
    notifyListeners();
  }

  Future<void> addMealEvent(String restaurantName, DateTime date, String paidBy, List<ExpenseItem> expenses, List<String> selectedUserIds) async {
    var event = MealEvent(
      id: const Uuid().v4(),
      date: date,
      paidBy: paidBy,
      restaurantName: restaurantName,
      expenses: expenses,
      userStatuses: selectedUserIds.map((id) => EventUserStatus(userId: id)).toList(),
    );
    _events.add(event);
    await _saveEventsToPrefs();
    try {
      await _firestore.collection('events').doc(event.id).set(event.toJson());
    } catch (e) {
      debugPrint('Firestore error: $e');
    }
    notifyListeners();

    try {
      final img = AdminNotifyController.savedImageFor('meal_bill');
      if (selectedUserIds.isNotEmpty) {
        final selectedUsers =
            _users.where((u) => selectedUserIds.contains(u.id)).toList();
        final identifiers = <String>{
          ...selectedUserIds,
          for (final u in selectedUsers) ...[
            u.id,
            u.name,
            if (u.email != null && u.email!.isNotEmpty) u.email!,
          ],
        };
        unawaited(
          PushSender.sendToUsers(
            userIds: identifiers,
            title: 'খাবারের বিল দিন',
            body: 'আজকের খাবারের বিল পরিশোধ করার জন্য বিনীত অনুরোধ করা হচ্ছে।',
            imageUrl: img.isEmpty ? null : img,
          ),
        );
      } else {
        unawaited(
          PushSender.broadcast(
            title: 'খাবারের বিল দিন',
            body: 'আজকের খাবারের বিল পরিশোধ করার জন্য বিনীত অনুরোধ করা হচ্ছে।',
            imageUrl: img.isEmpty ? null : img,
          ),
        );
      }
    } catch (e) {
      debugPrint('Auto notify meal error: $e');
    }
  }

  Future<void> addGiftEvent(String recipient, String itemName, double price, DateTime date, String paidBy, List<String> selectedUserIds) async {
    var event = GiftEvent(
      id: const Uuid().v4(),
      date: date,
      paidBy: paidBy,
      recipient: recipient,
      itemName: itemName,
      price: price,
      userStatuses: selectedUserIds.map((id) => EventUserStatus(userId: id)).toList(),
    );
    _events.add(event);
    await _saveEventsToPrefs();
    try {
      await _firestore.collection('events').doc(event.id).set(event.toJson());
    } catch (e) {
      debugPrint('Firestore error: $e');
    }
    notifyListeners();

    try {
      final img = AdminNotifyController.savedImageFor('gift_bill');
      if (selectedUserIds.isNotEmpty) {
        final selectedUsers =
            _users.where((u) => selectedUserIds.contains(u.id)).toList();
        final identifiers = <String>{
          ...selectedUserIds,
          for (final u in selectedUsers) ...[
            u.id,
            u.name,
            if (u.email != null && u.email!.isNotEmpty) u.email!,
          ],
        };
        unawaited(
          PushSender.sendToUsers(
            userIds: identifiers,
            title: 'গিফটের বিল দিন',
            body: 'আজকের গিফটের বিল পরিশোধ করার জন্য বিনীত অনুরোধ করা হচ্ছে।',
            imageUrl: img.isEmpty ? null : img,
          ),
        );
      } else {
        unawaited(
          PushSender.broadcast(
            title: 'গিফটের বিল দিন',
            body: 'আজকের গিফটের বিল পরিশোধ করার জন্য বিনীত অনুরোধ করা হচ্ছে।',
            imageUrl: img.isEmpty ? null : img,
          ),
        );
      }
    } catch (e) {
      debugPrint('Auto notify gift error: $e');
    }
  }

  Future<void> deleteEvent(String eventId) async {
    _events.removeWhere((e) => e.id == eventId);
    await _saveEventsToPrefs();
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      debugPrint('Firestore error: $e');
    }
    notifyListeners();
  }

  Future<void> updateMealEvent({
    required String eventId,
    required String restaurantName,
    required DateTime date,
    required String paidBy,
    required List<ExpenseItem> expenses,
    required List<String> selectedUserIds,
  }) async {
    int index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      var oldStatuses = _events[index].userStatuses;
      List<EventUserStatus> newStatuses = selectedUserIds.map((id) {
        var old = oldStatuses.cast<EventUserStatus?>().firstWhere(
          (s) => s?.userId == id,
          orElse: () => null,
        );
        return EventUserStatus(userId: id, isPaid: old?.isPaid ?? false);
      }).toList();

      final updatedEvent = MealEvent(
        id: eventId,
        date: date,
        paidBy: paidBy,
        restaurantName: restaurantName,
        expenses: expenses,
        userStatuses: newStatuses,
      );
      _events[index] = updatedEvent;
      await _saveEventsToPrefs();
      try {
        await _firestore.collection('events').doc(eventId).set(updatedEvent.toJson());
      } catch (e) {
        debugPrint('Firestore error: $e');
      }
      notifyListeners();
    }
  }

  Future<void> updateGiftEvent({
    required String eventId,
    required String recipient,
    required String itemName,
    required double price,
    required DateTime date,
    required String paidBy,
    required List<String> selectedUserIds,
  }) async {
    int index = _events.indexWhere((e) => e.id == eventId);
    if (index != -1) {
      var oldStatuses = _events[index].userStatuses;
      List<EventUserStatus> newStatuses = selectedUserIds.map((id) {
        var old = oldStatuses.cast<EventUserStatus?>().firstWhere(
          (s) => s?.userId == id,
          orElse: () => null,
        );
        return EventUserStatus(userId: id, isPaid: old?.isPaid ?? false);
      }).toList();

      final updatedEvent = GiftEvent(
        id: eventId,
        date: date,
        paidBy: paidBy,
        recipient: recipient,
        itemName: itemName,
        price: price,
        userStatuses: newStatuses,
      );
      _events[index] = updatedEvent;
      await _saveEventsToPrefs();
      try {
        await _firestore.collection('events').doc(eventId).set(updatedEvent.toJson());
      } catch (e) {
        debugPrint('Firestore error: $e');
      }
      notifyListeners();
    }
  }

  Future<void> toggleAllPaidStatusForUser(String userId, bool makePaid) async {
    for (var event in _events) {
      var statusIndex = event.userStatuses.indexWhere((s) => s.userId == userId);
      if (statusIndex != -1) {
        event.userStatuses[statusIndex].isPaid = makePaid;
        try {
          await _firestore.collection('events').doc(event.id).set(event.toJson());
        } catch (e) {
          debugPrint('Firestore error: $e');
        }
      }
    }
    await _saveEventsToPrefs();
    notifyListeners();
  }
}
