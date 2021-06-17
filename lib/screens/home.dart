import 'dart:io';
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
  List<Map<String,dynamic>> detailsPassDecrypted=List();
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
           String EncryptedPassword=await platformChannel.invokeMethod("Encrypt",{"text":passTextEditor.text});
           String encryptedName = await platformChannel.invokeMethod("Encrypt",{"text": siteTextEditor.text});
           details.addAll( {"Site":encryptedName,"Password":EncryptedPassword});
              helper.insertPass(details).whenComplete((){
                getDataFromDb();
              });
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
  Future getDataFromDb()async{
    List<Map<String,dynamic>> detailsPass=List();
    detailsPassDecrypted.clear();
    Directory directory=await getExternalStorageDirectory();
    print(directory.path);
    detailsPass=await helper.getAllPass();
    detailsPass.forEach((element)async {
   String decryptPassword= await platformChannel.invokeMethod('Decrypt',{"encryptedText":element["Password"]});
   String decryptSiteName = await platformChannel.invokeMethod("Decrypt",{'encryptedText': element['Site']});
    detailsPassDecrypted.add({"id":element["id"],"Site":decryptSiteName,"Password":decryptPassword});
    });
    setState(() {

    });
  }
  @override
  void initState() {
    getDataFromDb();
    super.initState();
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
  warningDelete(context,site,detailsPassDecrypted,helper){
    return showDialog(context:context,builder: (context){
      return AlertDialog(
        title: Text("Are you sure to delete ${site} password"),
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
              helper.deletePass(detailsPassDecrypted["id"]);
              this.detailsPassDecrypted.remove(detailsPassDecrypted);
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
      body: SmartRefresher(
        controller: refreshController,
        onRefresh: (){
          getDataFromDb().whenComplete((){
            refreshController.refreshCompleted();
          });
        },
        enablePullDown: true,
        header: WaterDropMaterialHeader(),
        child: ListView.builder(
          itemCount: detailsPassDecrypted.length,
          itemBuilder: (BuildContext context,i){
            return Dismissible(
              confirmDismiss: (direction)async{
                if(direction==DismissDirection.endToStart) {
                  return await(
                      warningDelete(context, detailsPassDecrypted[i]["Site"],
                          detailsPassDecrypted[i], helper)
                  );
                }
                else{


                  return await(
                      update(detailsPassDecrypted[i]['id'],detailsPassDecrypted[i]["Site"], detailsPassDecrypted[i]["Password"], context, platformChannel)
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
              key: Key(detailsPassDecrypted[i].toString()),
              child: InkWell(
               child:ListTile(
                title: Text(detailsPassDecrypted[i]["Site"]),
                subtitle: Text(detailsPassDecrypted[i]["Password"]),
                 trailing: isSwipeLeft?Icon(Icons.delete):null,
               )
              ),
            );
          },
        ),
      ),
    );
  }
  update(id,String site,String pass,context,platformChannel){
    TextEditingController siteTextEditor=TextEditingController();
    TextEditingController passTextEditor=TextEditingController();
    DatabaseHelper helper=DatabaseHelper();
    siteTextEditor.text=site;
    passTextEditor.text=pass;
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
              Map<String,dynamic> details=Map();
              String EncryptedPassword=await platformChannel.invokeMethod("Encrypt",{"text":passTextEditor.text});
              String encryptedName = await platformChannel.invokeMethod("Encrypt",{"text": siteTextEditor.text});
              details.addAll( {"id":id,"Site":encryptedName,"Password":EncryptedPassword});
              helper.updataPass(details).whenComplete((){
                getDataFromDb();
              });

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
