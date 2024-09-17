import 'dart:async';
import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import './firebase_options.dart'; // Import the generated firebase_options.dart

void main() async {
  // Ensure that widget binding is initialized before calling runApp
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the options from firebase_options.dart
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: "Product List"),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ProductList(),
    );
  }
}

class ProductList extends StatefulWidget {
  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final StreamController<List<DocumentSnapshot>> _streamController =
      StreamController<List<DocumentSnapshot>>();
  List<DocumentSnapshot> _products = [];

  bool _isRequesting = false;
  bool _isFinish = false;

  void onChangeData(List<DocumentChange> documentChanges) {
    bool isChange = false;
    documentChanges.forEach((productChange) {
      log("productChange ${productChange.type.toString()} ${productChange.newIndex} ${productChange.oldIndex} ${productChange.doc}");

      if (productChange.type == DocumentChangeType.removed) {
        _products.removeWhere((product) {
          return productChange.doc.id == product.id;
        });
        isChange = true;
      } else if (productChange.type == DocumentChangeType.modified) {
        int indexWhere = _products.indexWhere((product) {
          return productChange.doc.id == product.id;
        });

        if (indexWhere >= 0) {
          _products[indexWhere] = productChange.doc;
        }
        isChange = true;
      }
    });

    if (isChange) {
      _streamController.add(_products);
    }
  }

  @override
  void initState() {
    FirebaseFirestore.instance
        .collection('items')
        .snapshots()
        .listen((data) => onChangeData(data.docChanges));

    requestNextPage();
    super.initState();
  }

  @override
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification scrollInfo) {
        if (scrollInfo.metrics.maxScrollExtent == scrollInfo.metrics.pixels) {
          requestNextPage();
        }
        return true;
      },
      child: StreamBuilder<List<DocumentSnapshot>>(
        stream: _streamController.stream,
        builder: (BuildContext context,
            AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
          if (snapshot.hasError) return Text('Error: ${snapshot.error}');
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Text('Loading...');
            default:
              log("Items: ${snapshot.data!.length}");
              return ListView.separated(
                separatorBuilder: (context, index) => Divider(
                  color: Colors.black,
                ),
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: ListTile(
                    title: Text(snapshot.data?[index]['name']),
                    subtitle: Text(snapshot.data?[index]['description']),
                  ),
                ),
              );
          }
        },
      ),
    );
  }

  void requestNextPage() async {
    if (!_isRequesting && !_isFinish) {
      print("🚀 ~ _ProductListState ~ Widgetbuild ~ requestNextPage:");
      QuerySnapshot querySnapshot;
      _isRequesting = true;
      if (_products.isEmpty) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('items')
            .orderBy('index')
            .limit(5)
            .get();
      } else {
        querySnapshot = await FirebaseFirestore.instance
            .collection('items')
            .orderBy('index')
            .startAfterDocument(_products[_products.length - 1])
            .limit(5)
            .get();
      }

      int oldSize = _products.length;
      _products.addAll(querySnapshot.docs);
      int newSize = _products.length;
      if (oldSize != newSize) {
        _streamController.add(_products);
      } else {
        _isFinish = true;
      }
      _isRequesting = false;
    }
  }
}
