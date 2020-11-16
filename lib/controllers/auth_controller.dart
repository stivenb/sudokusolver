import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:sudokusolver/pages/index.dart';
import 'package:sudokusolver/pages/login.dart';

class AuthController extends GetxController {
  FirebaseAuth _auth = FirebaseAuth.instance;
  Rx<FirebaseUser> _firebaeUser = Rx<FirebaseUser>();
  String get user => _firebaeUser.value?.email;
  RxBool isLogged = false.obs;
  @override
  void onInit() {
    _firebaeUser.bindStream(_auth.onAuthStateChanged);
  }

  createUser(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      Get.off(Login());
    } catch (e) {
      Get.snackbar("Error creating account", e.toString(),
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  loginWithEmailAndPass(String email, String password) async {
    try {
      AuthResult user = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      if (user != null) {
        Get.to(Index());
      } else {
        Get.snackbar("Error sign in account", "User or password invalid",
            snackPosition: SnackPosition.BOTTOM);
      }
      Login().emailController.clear();
      Login().passwordController.clear();
    } catch (e) {
      Get.snackbar("Error sign in account", "User or password invalid",
          snackPosition: SnackPosition.BOTTOM);
    }
  }

  void signOut() async {
    try {
      await _auth.signOut();
      Get.off(Login());
    } catch (e) {
      Get.snackbar("Error sign out account", "User or password invalid",
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
