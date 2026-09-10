import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    await _firebaseAuth.setLanguageCode('es');
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    try {
      await credential.user?.updateDisplayName(displayName.trim());
    } on FirebaseAuthException {
      // El nombre es opcional y no debe invalidar una cuenta ya creada.
    }
    return credential;
  }

  Future<void> sendEmailVerification() async {
    await _firebaseAuth.setLanguageCode('es');
    final user = _firebaseAuth.currentUser;
    if (user == null) throw StateError('No hay una sesión activa.');
    await user.sendEmailVerification();
  }

  Future<User?> reloadCurrentUser() async {
    await _firebaseAuth.currentUser?.reload();
    return _firebaseAuth.currentUser;
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _firebaseAuth.setLanguageCode('es');
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }
}
