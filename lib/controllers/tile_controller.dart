import 'package:get/get.dart';

class TileController extends GetxController {
  List<int> mydata = new List.filled(81, 0, growable: true);
  var count = 1;

  void increment() {
    count++;
    print(mydata);
    update();
  }

  void change(int index, int text) {
    mydata[index] = text;
    print(mydata);
    update();
  }
}
