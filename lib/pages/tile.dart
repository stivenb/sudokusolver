import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sudokusolver/controllers/tile_controller.dart';

class Tile extends StatelessWidget {
  final index;
  Tile({Key key, this.index}) : super(key: key);
  final TextEditingController textController = TextEditingController();
  final TileController controller = Get.find<TileController>();
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: TextEditingController()
        ..text = controller.mydata[index].toString() == '0'
            ? ''
            : controller.mydata[index].toString(),
      onChanged: (text) {
        controller.change(index, int.parse(text));
      },
      keyboardType: TextInputType.number,
      style: TextStyle(),
      textAlign: TextAlign.center,
    );
  }
}
