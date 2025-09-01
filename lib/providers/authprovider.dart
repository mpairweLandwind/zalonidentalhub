import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/models/user_model.dart';

// AuthState to manage user authentication
class AuthState {
  final User? user;
  final UserModel? userModel;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.user,
    this.userModel,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    UserModel? userModel,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      user: user ?? this.user,
      userModel: userModel ?? this.userModel,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  AuthState build() => AuthState();

  // Register a new user
  Future<bool> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      UserModel newUser = UserModel(
        uid: userCredential.user!.uid,
        firstName: firstName,
        lastName: lastName,
        email: email,
        phoneNumber: phoneNumber,
      );

      await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(newUser.toMap());

      state = state.copyWith(
        user: userCredential.user,
        userModel: newUser,
        isLoading: false,
      );

      return true; // Registration successful
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
      return false; // Registration failed
    }
  }

  // Login user
  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      UserModel userModel =
          UserModel.fromMap(userDoc.data() as Map<String, dynamic>);

      state = state.copyWith(
        user: userCredential.user,
        userModel: userModel,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString(), isLoading: false);
    }
  }

  // Logout user
  Future<void> logout() async {
    await _auth.signOut();
    state = AuthState();
  }
}

// Provide the AuthNotifier to the app
final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
