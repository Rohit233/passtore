import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:passstore/screens/biometric.dart';
import 'package:passstore/screens/loginForm.dart';


void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,

      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, AsyncSnapshot<User> user) {
          if(user.connectionState == ConnectionState.waiting){
            return CircularProgressIndicator();
          }
          if(user.hasData){
            return Bio();
          }
          return LoginForm();
        }
      ),
    );
  }
}

