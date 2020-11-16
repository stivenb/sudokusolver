import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/get_state_manager.dart';
import 'package:sudokusolver/controllers/tile_controller.dart';
import 'package:sudokusolver/pages/tile.dart';
import 'package:http/http.dart' as http;

class ResultIA extends StatelessWidget {
  ResultIA({Key key}) : super(key: key);
  final TileController tileController = Get.put(TileController());

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
                      'IA',
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
                            onPressed: () {
                              print("paso a paso");
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18.0),
                              side: BorderSide(color: Color(0xFF527DAA)),
                            ),
                            child: Text('Show a help')),
                        RaisedButton(
                          onPressed: () async {
                            print("Solucion completa");
                            Get.dialog(
                                Center(child: CircularProgressIndicator()));
                            await _solveSudoku();
                            Get.back();
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(color: Color(0xFF527DAA)),
                          ),
                          child: Text('Show all the solution'),
                        )
                      ],
                    )
                  ]),
            )));
  }

  Future<void> _solveSudoku() async {
    var endpointUrl = 'http://192.168.1.4:4000/solveAll';
    Map<String, String> data = {'array': tileController.mydata.toString()};
    String queryString = Uri(queryParameters: data).query;
    var requestUrl = endpointUrl + '?' + queryString;
    var response = await http.post(requestUrl);
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