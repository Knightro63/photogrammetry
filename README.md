# photogrammetry

[![Pub Version](https://img.shields.io/pub/v/photogrammetry)](https://pub.dev/packages/photogrammetry)
[![analysis](https://github.com/Knightro63/photogrammetry/actions/workflows/flutter.yml/badge.svg)](https://github.com/Knightro63/photogrammetry/actions/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)

Photogrammetry is a Flutter plugin that enables Flutter apps to create 3D models from a series of images.

## Requirements

**MacOS**
 - Minimum osx Deployment Target: 12.0
 - Xcode 15 or newer
 - Swift 5
 - ML Kit only supports 64-bit architectures (x86_64 and arm64).

**iOS**
 - Minimum ios Deployment Target: 17.0
 - Xcode 15 or newer
 - Swift 5
 - ML Kit only supports 64-bit architectures (x86_64 and arm64).

## Getting Started

You need to first import 'package:photogrammetry/photogrammetry.dart';

```dart
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
              print('complete');
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
```

## Example

Find the example for this API [here](https://github.com/Knightro63/photogrammetry/tree/main/packages/photogrammetry/example/lib/main.dart).

## Contributing

Contributions are welcome.
In case of any problems look at [existing issues](https://github.com/Knightro63/photogrammetry/issues), if you cannot find anything related to your problem then open an issue.
Create an issue before opening a [pull request](https://github.com/Knightro63/photogrammetry/pulls) for non trivial fixes.
In case of trivial fixes open a [pull request](https://github.com/Knightro63/photogrammetry/pulls) directly.
