import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:passstore/screens/home.dart';
class Bio extends StatefulWidget {
  @override
  _BioState createState() => _BioState();
}

class _BioState extends State<Bio> {
  final platformChannel=MethodChannel("NativeCode/auth");
 String authStatus="";

  getAuth()async{
   authStatus=await platformChannel.invokeMethod("finger");
   setState(() {

   });
   if(authStatus=="succeeded"){
     Navigator.pushReplacement(context, MaterialPageRoute(builder: (context){
       return Home();
     }));
   }
  }
  @override
  void initState() {
    getAuth();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
            body: Center(
              child: Container(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(100.0),
                      child: authStatus==""? Icon(Icons.fingerprint,
                        size: 100,
                      ):authStatus=="Failed"?Icon(Icons.error,color: Colors.red,size: 100,): Icon(Icons.fingerprint,
                      size: 100,
                      ),
                    ),
                    authStatus!="Failed"?Container() :Text("Try Again"),
                    Text("Scan Finger to unlock")

                  ],
                ),
              ),
            ),
      ),
    );
  }
}
