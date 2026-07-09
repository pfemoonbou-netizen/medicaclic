import 'package:flutter/widgets.dart';
import '../models/app_user.dart';
import '../services/user_session.dart';

/// Propagates [UserSession] down the widget tree via InheritedNotifier.
/// Any widget that calls [UserScope.of] or [UserScope.userOf] will rebuild
/// automatically when the session changes.
///
/// Usage — wrap the root:
/// ```dart
/// UserScope(child: MaterialApp(...))
/// ```
///
/// Read from any descendant:
/// ```dart
/// final user = UserScope.userOf(context);
/// ```
class UserScope extends InheritedNotifier<UserSession> {
  UserScope({
    super.key,
    required super.child,
  }) : super(notifier: UserSession.instance);

  /// Returns the nearest [UserSession].
  static UserSession of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<UserScope>()!.notifier!;

  /// Returns the current [AppUser] and subscribes to updates.
  static AppUser userOf(BuildContext context) => of(context).current;
}
