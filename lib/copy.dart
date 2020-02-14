import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:path_provider/path_provider.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lista de tarefas',
      home: Home(),
      theme: ThemeData(
        primaryColor: Colors.green,
      ),
    );
  }
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPosition;

  var textControl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _readData().then((data) {
      setState(() {
        _toDoList = json.decode(data);
      });
    });
  }

  void addToDo() {
    // {"String": "Dynamic"}
    // a key no json sempre uma string e o value pode receber qualquer valor
    Map<String, dynamic> newToDo = Map();
    if (textControl.text != '') {
      newToDo['title'] = textControl.text;
      textControl.text = '';
      newToDo['value'] = false;
      setState(() {
        _saveData();
        _toDoList.add(newToDo);
      });
    }
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((atual, prximo) {
        if (!atual['value'] && prximo['value'])
          return 1;
        else if (atual['value'] && !prximo['value'])
          return -1;
        else
          return 0;
      });
      _saveData();
    });
  }

  Widget itemBuilder(BuildContext context, int index) {
    return Dismissible(
        key: Key(_toDoList[index]['title']),
        background: Container(
          color: Colors.red,
          child: Align(
            alignment: Alignment(-0.9, 0.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        direction: DismissDirection.startToEnd,
        onDismissed: (direction) {
          // (cria uma cópia (Um Map com 1 item) do Map toDoList passando
          // a posição do item na lista original)
          _lastRemoved = Map.from(_toDoList[index]);
          // salva a posição do item removido
          _lastRemovedPosition = index;
          setState(() {
            // remove da posição especificada
            _toDoList.removeAt(index);
          });

          final snack = SnackBar(
            content: Text("Tarefa ${_lastRemoved['title']} removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: () {
                setState(() {
                  // adiciona
                  _toDoList.insert(_lastRemovedPosition, _lastRemoved);
                  // atualiza o banco
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 2),
          );
          Scaffold.of(context).showSnackBar(snack);
        },
        child: CheckboxListTile(
          title: Text(_toDoList[index]['title']),
          value: _toDoList[index]['value'],
          secondary: CircleAvatar(
            backgroundColor: Colors.green,
            child: Icon(
              _toDoList[index]["value"] ? Icons.check : Icons.clear,
              color: Colors.white,
            ),
          ),
          onChanged: (bool value) {
            setState(() {
              _toDoList[index]['value'] = value;
              _saveData();
            });
          },
        ));
  }

  Future<File> _getFile() async {
    // Pega o caminho do diretório que permite salvar infos
    final directory = await getApplicationDocumentsDirectory();
    // retorna o diretorio (.path) (/data.json é o nome, pode ser qualquer outro .json)
    // que irá criar dentro da pasta de diretório o arquivo data.json
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista de tarefas'),
        centerTitle: true,
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.fromLTRB(17.0, 1.0, 7.0, 1.0),
            child: Row(
              children: <Widget>[
                // Expaned irá tentar ocupar o máximo possivel de largunra o seu child
                // Este widget é necessario pelo uso o Container().
                Expanded(
                  child: TextField(
                    controller: textControl,
                    decoration: InputDecoration(
                        labelText: "Nova tarefa",
                        labelStyle: TextStyle(color: Colors.green)),
                  ),
                ),
                RaisedButton(
                  textColor: Colors.white,
                  color: Colors.green,
                  child: Text("ADD"),
                  onPressed: addToDo,
                )
              ],
            ),
          ),
          Expanded(
              // ListView é um widget para construção de listas,
              // o método biulder evita que itens que não estão
              // visiveis sejam renderizados, poupando recursos
              // caso tenhamos uma lista muito grande
              child: RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 10.0),
              itemCount: _toDoList.length,
              itemBuilder: itemBuilder,
            ),
          ))
        ],
      ),
    );
  }
}
