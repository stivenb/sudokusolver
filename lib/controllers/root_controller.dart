import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:sudokusolver/pages/index.dart';
import 'package:sudokusolver/pages/login.dart';

class RootController extends GetxController {
  @override
  void onReady() {
    super.onReady();
    this.getUser();
  }

  Future getUser() async {
    var user = await FirebaseAuth.instance.currentUser();
    if (user != null) {
      Get.offAll(Index());
    } else {
      Get.offAll(Login());
    }
  }
}
// cual es la pagina por default?
//eche será la primera
