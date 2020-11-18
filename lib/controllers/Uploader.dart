import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sudokusolver/pages/results.dart';
import 'package:http/http.dart' as http;
import 'package:sudokusolver/controllers/tile_controller.dart';

class Uploader extends StatefulWidget {
  final File file;
  Uploader({Key key, this.file}) : super(key: key);
  @override
  _UploaderState createState() => _UploaderState();
}

class _UploaderState extends State<Uploader> {
  final TileController tileController = Get.put(TileController());
  final FirebaseStorage _storage =
      FirebaseStorage(storageBucket: 'gs://sudokuhelper-8201b.appspot.com');
  StorageUploadTask _uploadTask;

  void _startUpload() {
    String filePath = '${DateTime.now()}.png';
    setState(() {
      _uploadTask = _storage.ref().child(filePath).putFile(widget.file);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_uploadTask != null) {
      return StreamBuilder<StorageTaskEvent>(
          stream: _uploadTask.events,
          builder: (_, snapshot) {
            var event = snapshot?.data?.snapshot;

            double progressPercent = event != null
                ? event.bytesTransferred / event.totalByteCount
                : 0;

            return Column(
              children: [
                if (_uploadTask.isPaused)
                  FlatButton(
                    child: Icon(Icons.play_arrow),
                    onPressed: _uploadTask.resume,
                  ),
                if (_uploadTask.isInProgress)
                  FlatButton(
                    child: Icon(Icons.pause),
                    onPressed: _uploadTask.pause,
                  ),
                LinearProgressIndicator(value: progressPercent),
                Text('${(progressPercent * 100).toStringAsFixed(2)} % '),
                if (_uploadTask.isComplete)
                  FlatButton(
                    onPressed: () {
                      Get.dialog(Center(child: CircularProgressIndicator()),
                          barrierDismissible: false);
                      _getNumbers().then((value) => Get.to(ResultIA()));
                    },
                    child: Text('Solve'),
                    textColor: Colors.white,
                    color: Colors.blue,
                  ),
              ],
            );
          });
    } else {
      return FlatButton.icon(
        label: Text('Upload image'),
        icon: Icon(Icons.cloud_upload),
        onPressed: _startUpload,
      );
    }
  }

  Future<void> _getNumbers() async {
    var imageURL = await (await _uploadTask.onComplete).ref.getDownloadURL();
    var url = imageURL.toString();
    var endpointUrl = 'http://54.226.75.103:80/array';
    Map<String, String> data = {'imagelink': url};
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
        tileController.mydata[i] = z.toInt();
      } else {
        if (split[i] == '00') {
          tileController.mydata[i] = 0;
        } else {
          tileController.mydata[i] = double.parse(split[i]).toInt();
        }
      }
    }
  }
}
