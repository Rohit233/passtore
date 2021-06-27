import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:passstore/helperfiles/Database_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:swipedetector/swipedetector.dart';
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final siteTextEditor=TextEditingController();
  final passTextEditor=TextEditingController();
  final MethodChannel  platformChannel=MethodChannel("NativeCode/EncyAndDecry");
  DatabaseHelper helper=DatabaseHelper();
  RefreshController refreshController=RefreshController();
  bool isSwipeLeft=false;
  User user;
  _DialogForm(){
    showDialog(context: context,builder: (context){
      return AlertDialog(
        title: Text("Enter site and its Password"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(15))
        ),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Text("Site: "),
                title:TextField(
                 controller: siteTextEditor,
                ),
              ),
              ListTile(
                leading: Text("Password"),
                title:TextField(
                  controller: passTextEditor,
                ),
              )


            ],

          ),
        ),
        actions: <Widget>[
          RaisedButton(
            onPressed: ()async{
           Map<String,dynamic> details=Map();
           String encryptedPassword=await platformChannel.invokeMethod("Encrypt",{"text":passTextEditor.text});
           String encryptedName = await platformChannel.invokeMethod("Encrypt",{"text": siteTextEditor.text});
           details.addAll( {"Site":encryptedName,"Password":encryptedPassword,'userId':user.uid});
              helper.insertData(details);
              Navigator.pop(context);
            },
            child: Text("Store"),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(12))
            ),
          )
        ],
      );
    });
  }

  @override
  void initState() {
    user = FirebaseAuth.instance.currentUser;
    super.initState();
  }

Future<List<Map>> decryptPass(List listEncryptPass) async{
   List<Map> detailsPassDecrypted = [];
  await listEncryptPass.forEach((element)async {
      String decryptedSiteName = await platformChannel.invokeMethod("Decrypt",{"encryptedText":element.data()['site']});
      String decryptedPass = await platformChannel.invokeMethod("Decrypt",{"encryptedText":element.data()['password']});
      detailsPassDecrypted.add({'Site': decryptedSiteName,'Password':decryptedPass,'id':element.id,'created_at':element.data()['created_at']});
    });
  return detailsPassDecrypted; 
 }

  Widget slideLeftBackground(){
    return Container(
      color: Colors.red,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: <Widget>[
            Icon(
              Icons.delete,
              color: Colors.white,
            ),
            Text(
              " Delete",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(
              width: 20,
            ),
          ],
        ),
        alignment: Alignment.centerRight,
      ),
    );
  }
  Widget slideRightBackground() {
    return Container(
      color: Colors.green,
      child: Align(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 20,
            ),
            Icon(
              Icons.edit,
              color: Colors.white,
            ),
            Text(
              " Edit",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.left,
            ),
          ],
        ),
        alignment: Alignment.centerLeft,
      ),
    );
  }
  warningDelete(context,detailsPassDecrypted){
    return showDialog(context:context,builder: (context){
      return AlertDialog(
        title: Text("Are you sure to delete ${detailsPassDecrypted['Site']} password"),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0))
        ),
        actions: <Widget>[
          RaisedButton(
            onPressed: (){
              Navigator.pop(context);


            },
            child: Text("No"),
          ),
          RaisedButton(
            onPressed: (){
              helper.deleteData(detailsPassDecrypted);
             Navigator.pop(context);
             setState(() {

             });
            },
            child: Text("Yes"),
          )
        ],

      );
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(

      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          _DialogForm();
        },
        child: Icon(Icons.add),

      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: helper.getAllPass(),
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if(snapshot.connectionState == ConnectionState.waiting){
              return Center(child: CircularProgressIndicator());
            }
            if(snapshot.data == null || snapshot.data.docs.isEmpty){
              return Center(
                child: Text('No password found'),
              );
            }
            
            return FutureBuilder(
              future: decryptPass(snapshot.data.docs),
              initialData: [{}],
              builder: (context, snapshot) {
                if(snapshot.connectionState == ConnectionState.waiting){
                  return Center(child: CircularProgressIndicator());
                }
                return snapshot.data.isEmpty ? Text('None') :ListView.builder(
                  itemCount: snapshot.data.length,
                  itemBuilder: (BuildContext context,i){
                    return Dismissible(
                      confirmDismiss: (direction)async{
                        if(direction==DismissDirection.endToStart) {
                          return await(
                              warningDelete(context,snapshot.data[i])
                          );
                        }
                        else{


                          return await(
                              update(snapshot.data[i], context, platformChannel)
                          );

                        }

                      },
                      onDismissed: (direction){
                        if(DismissDirection.endToStart==direction){

                        }
                        else if(DismissDirection.startToEnd==direction){


                        }

                      },
                      background: slideRightBackground(),
                      secondaryBackground: slideLeftBackground(),
                      key: Key(snapshot.data[i].toString()),
                      child: InkWell(
                       child:ListTile(
                        title: Text(snapshot.data[i]["Site"]),
                        subtitle: Text(snapshot.data[i]["Password"]),
                         trailing: isSwipeLeft?Icon(Icons.delete):null,
                       )
                      ),
                    );
                  },
                );
              }
            );
          }
        ),
    );
  }
  update(Map details,context,platformChannel){
    TextEditingController siteTextEditor=TextEditingController();
    TextEditingController passTextEditor=TextEditingController();
    DatabaseHelper helper=DatabaseHelper();
    siteTextEditor.text=details['Site'];
    passTextEditor.text=details['Password'];
    return showDialog(context: context,builder: (context){
      return AlertDialog(
        title: Text("Enter site and its Password"),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))
        ),
        content: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ListTile(
                leading: Text("Site: "),
                title:TextField(
                  controller: siteTextEditor,
                ),
              ),
              ListTile(
                leading: Text("Password"),
                title:TextField(
                  controller: passTextEditor,
                ),
              )


            ],

          ),
        ),
        actions: <Widget>[
          RaisedButton(
            onPressed: ()async{
              Map<String,dynamic> updatedDetails=Map();
              String encryptedPassword=await platformChannel.invokeMethod("Encrypt",{"text":passTextEditor.text});
              String encryptedName = await platformChannel.invokeMethod("Encrypt",{"text": siteTextEditor.text});
              updatedDetails.addAll( {"id":details['id'],'created_at':details['created_at'],"Site":encryptedName,"Password":encryptedPassword,'userId':user.uid});
              helper.updateData(updatedDetails);
              Navigator.pop(context);
              setState(() {

              });

            },
            child: Text("Store"),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))
            ),
          )
        ],
      );
    });
  }
}
