import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:sudokusolver/controllers/tile_controller.dart';
import 'package:sudokusolver/pages/tile.dart';
import 'package:http/http.dart' as http;

class ResultIA extends StatelessWidget {
  ResultIA({Key key}) : super(key: key);
  final TileController tileController = Get.put(TileController());
  bool sw = true;
  bool sw1 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Container(
            height: double.infinity,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF73AEF5),
                  Color(0xFF61A4F1),
                  Color(0xFF478DE0),
                  Color(0xFF398AE5),
                ],
                stops: [0.1, 0.4, 0.7, 0.9],
              ),
            ),
            child: Container(
              height: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: 40.0,
                vertical: 50.0,
              ),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'SUDOKU',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'OpenSans',
                        fontSize: 25.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    _buildGrid(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        RaisedButton(
                            onPressed: () async {
                              _isComplete();
                              if (sw == true) {
                                Get.dialog(
                                    Center(child: CircularProgressIndicator()),
                                    barrierDismissible: false);
                                await _giveHint();
                                Get.back();
                                if (sw1) {
                                  Get.snackbar('Wrong Sudoku',
                                      'The sudoku table is wrong');
                                }
                              } else {
                                Get.snackbar('Table complete',
                                    'The sudoku table is full ');
                              }
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                              side: BorderSide(color: Color(0xFF527DAA)),
                            ),
                            child: Text('Show hint')),
                        RaisedButton(
                          onPressed: () async {
                            _isComplete();
                            if (sw == true) {
                              Get.dialog(
                                  Center(child: CircularProgressIndicator()),
                                  barrierDismissible: false);
                              await _solveSudoku();
                              Get.back();
                              if (sw1) {
                                Get.snackbar('Wrong Sudoku',
                                    'The sudoku table is wrong');
                              }
                            } else {
                              Get.snackbar('Table complete',
                                  'The sudoku table is full ');
                            }
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(color: Color(0xFF527DAA)),
                          ),
                          child: Text('Show all the solutions'),
                        )
                      ],
                    )
                  ]),
            )));
  }

  Future<void> _giveHint() async {
    var endpointUrl = 'http://54.226.75.103:80/hint';
    Map<String, String> data = {'array': tileController.mydata.toString()};
    String queryString = Uri(queryParameters: data).query;
    var requestUrl = endpointUrl + '?' + queryString;
    var response = await http.post(requestUrl);
    if (response.statusCode == 500) {
      sw1 = true;
    } else {
      sw1 = false;
      var split = response.body.split(",");
      for (var i = 0; i < split.length; i++) {
        if (i == 0) {
          split[i] = split[i].replaceAll(new RegExp(r"[^\s\w]"), "");
        }
        split[i] = split[i].replaceAll("[", "");
        split[i] = split[i].replaceAll("]", "");
        split[i] = split[i].replaceAll('array', "");
        split[i] = split[i].replaceAll("{", "");
        split[i] = split[i].replaceAll("}", "");
      }
      for (var i = 0; i < split.length; i++) {
        if (double.parse(split[i]).toInt() >= 10) {
          var x = double.parse(split[i]).toInt();
          var z = x / 10;
          tileController.change(i, z.toInt());
        } else {
          if (split[i] == '00') {
            tileController.change(i, 0);
          } else {
            tileController.change(i, double.parse(split[i]).toInt());
          }
        }
      }
    }
  }

  Widget _isComplete() {
    var count = 0;
    for (var i = 0; i < tileController.mydata.length; i++) {
      count = count + tileController.mydata[i];
    }
    if (count == 405) {
      sw = false;
    } else {
      sw = true;
    }
  }

  Future<void> _solveSudoku() async {
    var endpointUrl = 'http://54.226.75.103:80/solveAll';
    Map<String, String> data = {'array': tileController.mydata.toString()};
    String queryString = Uri(queryParameters: data).query;
    var requestUrl = endpointUrl + '?' + queryString;
    var response = await http.post(requestUrl);
    if (response.statusCode == 500) {
      sw1 = true;
    } else {
      sw1 = false;
      var split = response.body.split(",");
      for (var i = 0; i < split.length; i++) {
        if (i == 0) {
          split[i] = split[i].replaceAll(new RegExp(r"[^\s\w]"), "");
        }
        split[i] = split[i].replaceAll("[", "");
        split[i] = split[i].replaceAll("]", "");
        split[i] = split[i].replaceAll('array', "");
        split[i] = split[i].replaceAll("{", "");
        split[i] = split[i].replaceAll("}", "");
      }
      for (var i = 0; i < split.length; i++) {
        if (double.parse(split[i]).toInt() >= 10) {
          var x = double.parse(split[i]).toInt();
          var z = x / 10;
          tileController.change(i, z.toInt());
        } else {
          if (split[i] == '00') {
            tileController.change(i, 0);
          } else {
            tileController.change(i, double.parse(split[i]).toInt());
          }
        }
      }
    }
  }

  Widget _buildGrid() {
    return GetBuilder<TileController>(
        init: TileController(),
        builder: (_) => Expanded(
                child: GridView.count(
              crossAxisCount: 9,
              scrollDirection: Axis.vertical,
              children: List.generate(81, (index) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border(
                        right: BorderSide(
                            color: (index + 1) % 3 == 0
                                ? Colors.black
                                : Colors.grey),
                        bottom: BorderSide(
                            color: bottomBorder(index)
                                ? Colors.black
                                : Colors.transparent)),
                    color: Colors.grey[200],
                  ),
                  height: 100,
                  width: 100,
                  child: Center(
                    child: Tile(
                      index: index,
                    ),
                  ),
                );
              }),
            )));
  }

  bool bottomBorder(var index) {
    if (index >= 18 && index <= 26 || index >= 45 && index <= 53) {
      return true;
    }
    return false;
  }
}
