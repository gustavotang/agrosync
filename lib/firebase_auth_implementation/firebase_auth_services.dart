import 'package:firebase_auth/firebase_auth.dart';
import 'package:agrosync/models/toast.dart';

class FirebaseAuthService {

  FirebaseAuth _auth = FirebaseAuth.instance;

  Future<User?> signUpWithEmailAndPassword(String email, String password) async {

    try {
      UserCredential credential =await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {

      switch (e.code) {
        case 'email-already-in-use':
          showToast(message: 'O email já está sendo usado');
          break;
        case 'weak-password':
          showToast(message: 'A senha está fraca');
          break;
        case 'invalid-email':
          showToast(message: 'Email inválido');
          break;
        default:
          showToast(message: 'Verificar usuario e senha: ${e.code}');
      }
    }
    return null;

  }

  Future<User?> signInWithEmailAndPassword(String email, String password) async {

    try {
      UserCredential credential =await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } on FirebaseAuthException catch (e) {
      
      switch (e.code) {
        case 'user-not-found':
          showToast(message: 'Email não encontrado');
          break;
        case 'wrong-password':
          showToast(message: 'Senha está incorreta');
          break;
        case 'invalid-email':
          showToast(message: 'Email inválido');
          break;
        default:
          showToast(message: 'Verificar usuario e senha: ${e.code}');
      }

    }
    return null;

  }




}


