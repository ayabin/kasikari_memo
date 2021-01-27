import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:share/share.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'かしかりメモ',
      routes: <String, WidgetBuilder>{
        '/': (_) => Splash(),
        '/list': (_) => MyList(),
      },
      // home: MyList(),
    );
  }
}

class MyList extends StatefulWidget {
  @override
  _MyListState createState() => _MyListState();
}

class _MyListState extends State<MyList> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("リスト画面"),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              showBasicDialog(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .collection('transaction')
              .snapshots(),
          builder:
              (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (!snapshot.hasData)
              return Center(
                child: CircularProgressIndicator(),
              );
            return ListView.builder(
              itemCount: snapshot.data.docs.length,
              itemBuilder: (context, index) =>
                  _buildListItem(context, snapshot.data.docs[index]),
              padding: const EdgeInsets.only(top: 10),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          print('Add onPressed');
          Navigator.of(context).push(
            MaterialPageRoute(
              settings: const RouteSettings(name: "/new"),
              builder: (BuildContext context) => InputForm(null),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot document) {
    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.android),
            title: Text("【" +
                (document['borrowOrLend'] == "lend" ? "貸" : "借") +
                "】" +
                document['stuff']),
            subtitle: Text('期限：' +
                document['date'].toDate().toString().substring(0, 10) +
                "\n相手：" +
                document['user']),
          ),
          ButtonTheme(
              child: ButtonBar(
            children: [
              TextButton(
                onPressed: () {
                  print('Edit onPressed');
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      settings: const RouteSettings(name: "/edit"),
                      builder: (BuildContext context) => InputForm(document),
                    ),
                  );
                },
                child: const Text('Edit'),
              ),
            ],
          ))
        ],
      ),
    );
  }
}

void showBasicDialog(BuildContext context) {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String email, password;
  if (firebaseUser.isAnonymous) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text('ログイン/登録ダイアログ'),
        content: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.mail),
                  labelText: 'Email',
                ),
                onSaved: (String value) {
                  email = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Emailは必須です';
                  }
                  return null; //問題ないときはnullを返す
                },
              ),
              TextFormField(
                obscureText: true,
                decoration: const InputDecoration(
                  icon: Icon(Icons.vpn_key),
                  labelText: 'Password',
                ),
                onSaved: (String value) {
                  password = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Passwordは必須です';
                  }
                  if (value.length < 6) {
                    return 'Passwordは６桁以上です';
                  }
                  return null; //問題ないときはnullを返す
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState.validate()) {
                _formKey.currentState.save();
                _createUser(context, email, password);
              }
            },
            child: const Text('登録'),
          ),
          TextButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  _formKey.currentState.save();
                  _signIn(context, email, password);
                }
              },
              child: const Text('ログイン')),
        ],
      ),
    );
  } else {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('確認ダイアログ'),
        content: Text(firebaseUser.email + "でログインしています"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _auth.signOut();
              Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

void _signIn(BuildContext context, String email, String password) async {
  try {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    Navigator.pushNamedAndRemoveUntil(context, "/", (_) => false);
  } catch (e) {
    Fluttertoast.showToast(msg: "Firebaseのログインに失敗しました");
  }
}

void _createUser(BuildContext context, String email, String password) async {
  try {
    await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
  } catch (e) {
    Fluttertoast.showToast(msg: "Firebaseの登録に失敗しました");
  }
}

User firebaseUser; // FirebaseUserからUserに変更 From firebase_auth 0.18.0
final FirebaseAuth _auth = FirebaseAuth.instance;

class Splash extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    _getUser(context);
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: FractionallySizedBox(
          child: Image.asset('images/note.png'),
          heightFactor: 0.4,
          widthFactor: 0.4,
        ),
      ),
    );
  }
}

void _getUser(BuildContext context) async {
  try {
    //currenUser()メソッドはcurrentUser（getter）に変更された
    firebaseUser = await _auth
        .currentUser; //_auth.currentUserはFutureではないがawaitを入れないとエラーがthrowされる
    if (firebaseUser == null) {
      await _auth.signInAnonymously();
      firebaseUser = _auth.currentUser;
    }
    Navigator.pushReplacementNamed(context, "/list");
  } catch (e) {
    Fluttertoast.showToast(msg: "Firebaseとの接続に失敗しました");
  }
}

class _FormData {
  String borrowOrLend = "borrow";
  String user;
  String stuff;
  DateTime date = DateTime.now();
}

class InputForm extends StatefulWidget {
  InputForm(this.document);
  final DocumentSnapshot document;

  @override
  _InputFormState createState() => _InputFormState();
}

class _InputFormState extends State<InputForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _FormData _data = _FormData();
  Future<DateTime> _selectTime(BuildContext context) {
    return showDatePicker(
      context: context,
      initialDate: _data.date,
      firstDate: DateTime(_data.date.year - 2),
      lastDate: DateTime(_data.date.year + 2),
    );
  }

  void _setLendOrRent(String value) {
    setState(() {
      _data.borrowOrLend = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    DocumentReference _mainReference;
    _mainReference = FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .collection('transaction')
        .doc();
    bool deleteFlg = false;
    if (widget.document != null) {
      if (_data.user == null && _data.stuff == null) {
        _data.borrowOrLend = widget.document['borrowOrLend'];
        _data.user = widget.document['user'];
        _data.stuff = widget.document['stuff'];
        _data.date = widget.document['date'].toDate(); //toDate()追加
      }
      _mainReference = FirebaseFirestore.instance
          .collection('kasikari-memo')
          .doc(widget.document.id); //documentIDをidに変更
      deleteFlg = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('かしかり入力'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: () {
              print('Save onPressed');
              if (_formKey.currentState.validate()) {
                _formKey.currentState.save();
                _mainReference.set(
                  {
                    'borrowOrLend': _data.borrowOrLend,
                    'user': _data.user,
                    'stuff': _data.stuff,
                    'date': _data.date
                  },
                );
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () {
              print('Delete onPressed');
              _mainReference.delete();
              Navigator.pop(context);
            },
          ),
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              if (_formKey.currentState.validate()) {
                _formKey.currentState.save();
                Share.share("【" +
                    (_data.borrowOrLend == "lend" ? "貸" : "借") +
                    "】" +
                    _data.stuff +
                    "\n期限：" +
                    _data.date.toString().substring(0, 10) +
                    "\n相手：" +
                    _data.user +
                    "\n#かしかりメモ");
              }
            },
          )
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              RadioListTile(
                value: "borrow",
                title: Text('借りた'),
                groupValue: _data.borrowOrLend,
                onChanged: (String value) {
                  _setLendOrRent(value);
                },
              ),
              RadioListTile(
                value: "lend",
                title: Text('貸した'),
                groupValue: _data.borrowOrLend,
                onChanged: (String value) {
                  _setLendOrRent(value);
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.person),
                  hintText: '相手の名前',
                  labelText: 'Name',
                ),
                onSaved: (String value) {
                  _data.user = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return '名前は必須項目です';
                  }
                  return null; //問題ないときはnullを返す
                },
                initialValue: _data.user,
              ),
              TextFormField(
                decoration: const InputDecoration(
                  icon: const Icon(Icons.business_center),
                  hintText: '借りたもの、貸したもの',
                  labelText: 'loan',
                ),
                onSaved: (String value) {
                  _data.stuff = value;
                },
                validator: (value) {
                  if (value.isEmpty) {
                    return '借りたもの、貸したものは必須項目です';
                  }
                  return null; //問題ないときはnullを返す
                },
                initialValue: _data.stuff,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text("締切日：${_data.date.toString().substring(0, 10)}"),
              ),
              ElevatedButton(
                onPressed: () {
                  print("締切日変更をタッチしました");
                  _selectTime(context).then((time) {
                    if (time != null && _data.date != null) {
                      setState(() {
                        _data.date = time;
                      });
                    }
                  });
                },
                child: const Text("締切日変更"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
