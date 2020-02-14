import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

void main() => runApp(App());

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de tarefas',
      home: Home(),
      theme: ThemeData(primaryColor: Colors.blueGrey),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  var textController = TextEditingController();
  Map<String, dynamic> _lastRemoved;
  int _positionLastRemoved;

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/data.json');
  }

  Future<File> _saveData() async {
    // converte a lista em json
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (error) {
      return null;
    }
  }

  void _clearController() {
    textController.text = '';
  }

  void _addData() async {
    Map<String, dynamic> newToDo = Map();
    if (textController.text != '') {
      newToDo['title'] = textController.text;
      newToDo['value'] = false;
      setState(() {
        _toDoList.add(newToDo);
      });
      _saveData();
      _clearController();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Lista de tarefas',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: <Widget>[
          // TextField, Button
          Container(
              padding: EdgeInsets.fromLTRB(17, 2, 17, 2),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: textController,
                    ),
                  ),
                  RaisedButton(
                    color: Colors.blueGrey,
                    child: Text(
                      "ADD",
                      style: TextStyle(color: Colors.white),
                    ),
                    onPressed: _addData,
                  )
                ],
              )),
          Expanded(
            child: ListView.builder(
              itemCount: _toDoList.length,
              itemBuilder: (BuildContext context, int index) {
                return Dismissible(
                  key: Key(_toDoList[index]['title']),
                  background: Container(
                    color: Colors.red,
                    child: Align(
                      alignment: Alignment(-0.9, 0.0),
                      child: Icon(Icons.clear),
                    ),
                  ),
                  direction: DismissDirection.startToEnd,
                  onDismissed: (direcition) {
                    _lastRemoved = Map.from(_toDoList[index]);
                    _positionLastRemoved = index;
                    setState(() {
                      _toDoList.removeAt(index);
                      _saveData();
                    });

                    final snack = SnackBar(
                      content: Text('Tarefa ${_lastRemoved["title"]} removida'),
                      action: SnackBarAction(
                        label: "Desfazer",
                        onPressed: () {
                          setState(() {
                            _toDoList.insert(
                                _positionLastRemoved, _lastRemoved);
                          });
                          _saveData();
                        },
                      ),
                      duration: Duration(seconds: 2),
                    );
                    Scaffold.of(context).showSnackBar(snack);
                  },
                  child: CheckboxListTile(
                    title: Text(_toDoList[index]['title']),
                    value: _toDoList[index]['value'],
                    onChanged: (value) {
                      setState(() {
                        _toDoList[index]['value'] = value;
                      });
                    },
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
