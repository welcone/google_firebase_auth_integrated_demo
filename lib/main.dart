import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'widgets/Auth.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baby Names',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var _selectedOption = 0;
  //>1
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        items: _buildBottomItems,
        onTap: (index) {
          setState(() {
            _selectedOption = index;
          });
        },
        currentIndex: _selectedOption,
      ),
      appBar: AppBar(title: Text('Google FireBase EX')),
      body: pages4BottomNavigationor[_selectedOption],
    );
  }

  //>2
  get _buildBottomItems {
    return List<BottomNavigationBarItem>.generate(2, (int index) {
      switch (index) {
        case 0:
          {
            return BottomNavigationBarItem(
                icon: Icon(Icons.cloud), title: Text('谷歌云数据库'));
          }
        case 1:
          {
            return BottomNavigationBarItem(
                icon: Icon(Icons.people), title: Text('谷歌电话登陆'));
          }
      }
    });
  }
  //>3
  var pages4BottomNavigationor = [];
  //>4
  @override
  void initState() {
    super.initState();
    pages4BottomNavigationor.addAll([
      _buildGoogleCloudSaver(context),
      Auth(),/// 导航到谷歌登陆
    ]);
  }
  //>5
  Widget _buildGoogleCloudSaver(BuildContext context) {
    return StreamBuilder(
        stream: Firestore.instance.collection('baby').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();
          return _buildList(context, snapshot.data.documents);
        });
  }
  /// 获取云数据的数据
  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: const EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }
  /// for _buildList
  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final record = Record.fromSnapshot(data);
    return Padding(
      key: ValueKey(record.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Text(record.name),
          trailing: Text(record.votes.toString()),
          onTap: () => record.reference.updateData({'votes': record.votes + 1}),
        ),
      ),
    );
  }
}
/// 数据类
class Record {
  final String name;
  final int votes;
  final DocumentReference reference;

  Record.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        name = map['name'],
        votes = map['votes'];

  Record.fromSnapshot(DocumentSnapshot snapshot)
      : this.fromMap(snapshot.data, reference: snapshot.reference);
  @override
  String toString() => "Record<$name:$votes>";
}
