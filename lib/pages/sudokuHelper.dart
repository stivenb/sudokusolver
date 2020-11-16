import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sudokusolver/controllers/Uploader.dart';

class SudokuHelper extends StatefulWidget {
  @override
  _SudokuHelperState createState() => _SudokuHelperState();
}

class _SudokuHelperState extends State<SudokuHelper> {
  File _imageFile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomAppBar(
        child: Row(
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.photo_camera),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            IconButton(
              icon: Icon(Icons.photo_library),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      ),
      body: ListView(
        children: <Widget>[
          if (_imageFile != null) ...[
            Image.file(_imageFile),
            Row(
              children: <Widget>[
                FlatButton(
                  onPressed: _clear,
                  child: Icon(Icons.refresh),
                ),
              ],
            ),
            Uploader(file: _imageFile)
          ]
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    PickedFile pickedFile = await picker.getImage(source: source);
    File selected = File(pickedFile.path);

    setState(() {
      _imageFile = selected;
    });
  }

  void _clear() {
    setState(() => _imageFile = null);
  }
}
