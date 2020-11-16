import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sudokusolver/controllers/root_controller.dart';

class Root extends StatefulWidget {
  Root({Key key}) : super(key: key);

  @override
  _RootState createState() => _RootState();
}

class _RootState extends State<Root> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<RootController>(
        init: RootController(),
        builder: (_) => Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ));
  }
}
