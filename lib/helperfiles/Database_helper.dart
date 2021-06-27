import 'dart:async';
import 'dart:core';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseHelper{

Future insertData(Map details)async{
   await FirebaseFirestore.instance.collection('passwords').add({
     'site': details['Site'],
     'password': details['Password'],
     'userId': details['userId'],
     'created_at': DateTime.now().millisecondsSinceEpoch
   });
}
 Future updateData(Map details)async{
   await FirebaseFirestore.instance.collection('passwords').doc(details['id']).set({
     'site': details['Site'],
     'password': details['Password'],
     'userId': details['userId'],
     'updated_at': DateTime.now().millisecondsSinceEpoch,
     'created_at': details['created_at']
   });
 }
 Future deleteData(Map details) async{
   await FirebaseFirestore.instance.collection('passwords').doc(details['id']).delete();
 }
 Stream<QuerySnapshot> getAllPass(){
   return FirebaseFirestore.instance.collection('passwords').where('userId',isEqualTo : FirebaseAuth.instance.currentUser.uid).orderBy('created_at').snapshots();
  }
}