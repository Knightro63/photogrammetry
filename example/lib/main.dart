import 'package:flutter/material.dart';
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:photogrammetry/photogrammetry.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isProcessing = false;
  String? complete;
  Photogrammetry? pg;
  String? path;

  @override
  void initState(){
    super.initState();
  }
  @override
  void dispose(){
    pg?.dispose();
    super.dispose();
  }

  Future<void> selectFolder() async {
    try {
      await FilePicker.platform.getDirectoryPath().then((value){
        if(value != null){
          setState((){
            isProcessing = true;
          });
          pg = Photogrammetry()..process(
            pgData: PhotogrammetryData(
              path: value,
              name: 'TestHuman1',
              quality: PhotogrammetryQuality.preview
            ),
            onDownsampling: (){
              print('onDownsampling');
            },
            onCanceled: (){
              setState((){
                isProcessing = false;
                complete = null;
              });
            },
            onSkipped: (id){
              print('Skipped: $id');
            },
            onError: (i,j,k,l){

            },
            onInvalidSample: (id,reason){
              print('InvalidSample: $id, $reason');
            },
            onStartedProcessing: (){
              print('onStartedProcessing');
            },
            onProgressChanged: (progress){
              setState(() {
                complete = '${(progress*100).toStringAsFixed(2)}%';
              });
            },
            onProcessingCompleted: (path){
              this.path = path;
            },
            onComplete: (){
              setState((){
                isProcessing = false;
                complete = null;
              });
            }
          );
        }
      });
    } 
    on PlatformException catch (e) {
      print('Unsupported operation Select: $e');
    } 
    catch (e) {
      print('Select: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Click the folder icon to get started!',
            ),
            Text(
              isProcessing?'Processing':'Not Processing',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if(complete != null || path != null)Text(
              complete != null?complete!:path != null?path!:'',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            InkWell(
              onTap: selectFolder,
              child: Container(
                width: 140,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(5)
                ),
                padding: const EdgeInsets.fromLTRB(10,0,10,0),
                margin: EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.folder,
                      color: Colors.purple[900]
                    ),
                    Text(
                      'Choose Folder',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.purple[900]),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          pg?.abort();
        },
        tooltip: 'Increment',
        backgroundColor: Colors.purple[100],
        child: Icon(Icons.cancel, color: Colors.purple[900],),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
