import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/models/user_model.dart';

/// Authentication state — immutable, with explicit null-clearing via [copyWith].
class AuthState {
  final User? user;
  final UserModel? userModel;
  final bool isLoading;
  final String? errorMessage;
  final bool isInitialized;

  const AuthState({
    this.user,
    this.userModel,
    this.isLoading = false,
    this.errorMessage,
    this.isInitialized = false,
  });

  bool get isAuthenticated => user != null;

  bool get isEmailVerified => user?.emailVerified ?? false;

  /// [clearUser] / [clearUserModel] / [clearError] allow explicit null-setting,
  /// since normal [copyWith] preserves existing values when null is passed.
  AuthState copyWith({
    User? user,
    UserModel? userModel,
    bool? isLoading,
    String? errorMessage,
    bool? isInitialized,
    bool clearUser = false,
    bool clearUserModel = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      userModel: clearUserModel ? null : (userModel ?? this.userModel),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  StreamSubscription<User?>? _authSub;

  @override
  AuthState build() {
    // Subscribe to Firebase auth state changes for session hydration.
    _authSub?.cancel();
    _authSub = _auth.authStateChanges().listen(_onAuthStateChanged);
    ref.onDispose(() => _authSub?.cancel());
    return const AuthState();
  }

  /// Called whenever Firebase auth state changes (login, logout, token refresh).
  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      state = const AuthState(isInitialized: true);
      return;
    }

    // Fetch the user profile from Firestore.
    try {
      final doc =
          await _firestore.collection('users').doc(firebaseUser.uid).get();
      final userModel = doc.exists
          ? UserModel.fromMap(doc.data() as Map<String, dynamic>)
          : null;

      state = AuthState(
        user: firebaseUser,
        userModel: userModel,
        isInitialized: true,
      );
    } catch (e) {
      state = AuthState(
        user: firebaseUser,
        errorMessage: 'Failed to load profile: $e',
        isInitialized: true,
      );
    }
  }

  /// Clear any displayed error.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // ─── Registration ──────────────────────────────────────────────

  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final newUser = UserModel(
        uid: cred.user!.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
      );

      await _firestore
          .collection('users')
          .doc(cred.user!.uid)
          .set(newUser.toMap());

      // Send verification email after registration.
      await cred.user!.sendEmailVerification();

      state = state.copyWith(
        user: cred.user,
        userModel: newUser,
        isLoading: false,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        errorMessage: _friendlyAuthError(e),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ─── Login ─────────────────────────────────────────────────────

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final doc =
          await _firestore.collection('users').doc(cred.user!.uid).get();
      final userModel =
          UserModel.fromMap(doc.data() as Map<String, dynamic>);

      state = state.copyWith(
        user: cred.user,
        userModel: userModel,
        isLoading: false,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        errorMessage: _friendlyAuthError(e),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ─── Logout ────────────────────────────────────────────────────

  Future<void> logout() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.signOut();
      // authStateChanges listener will reset state.
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  // ─── Email Verification ────────────────────────────────────────

  Future<bool> sendEmailVerification() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.currentUser?.sendEmailVerification();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;
    if (user != null) {
      state = state.copyWith(user: user);
    }
  }

  // ─── Password Reset ────────────────────────────────────────────

  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _auth.sendPasswordResetEmail(email: email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ─── Update Profile ────────────────────────────────────────────

  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String phoneNumber,
  }) async {
    final uid = state.user?.uid;
    if (uid == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _firestore.collection('users').doc(uid).update({
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phoneNumber,
      });

      final updated = state.userModel?.copyWith(
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
      );
      state = state.copyWith(userModel: updated, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ─── Delete Account ────────────────────────────────────────────

  Future<bool> deleteAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Re-authenticate before destructive action.
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);

      // Remove Firestore profile.
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete auth account — authStateChanges will reset state.
      await user.delete();
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        errorMessage: _friendlyAuthError(e),
        isLoading: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false;
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────

  String _friendlyAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'requires-recent-login':
        return 'Please log in again before this action.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

// Provide the AuthNotifier to the app.
final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
