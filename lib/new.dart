import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';

class FirestoreUpdate extends StatefulWidget {
  @override
  _FirestoreUpdateState createState() => _FirestoreUpdateState();
}

class _FirestoreUpdateState extends State<FirestoreUpdate> {
  List<DocumentSnapshot> _products = [];

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore.instance
        .collection('items')
        .snapshots()
        .listen((data) => onChangeData(data.docChanges));
    return Container();
  }

  void requestNextPage() async {}

  void onChangeData(List<DocumentChange> documentChanges) {
    documentChanges.forEach((productChange) {
      print(
          "productChange ${productChange.type.toString()} ${productChange.newIndex} ${productChange.oldIndex} ${productChange.doc}");

      if (productChange.type == DocumentChangeType.removed) {
        _products.removeWhere((product) {
          return productChange.doc.id == product.id;
        });
      } else {
        if (productChange.type == DocumentChangeType.modified) {
          int indexWhere = _products.indexWhere((product) {
            return productChange.doc.id == product.id;
          });

          if (indexWhere >= 0) {
            _products[indexWhere] = productChange.doc;
          }
        }
      }
    });
  }
}
