import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_opencv_example/native_opencv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tesseract_ocr/tesseract_ocr.dart';

import 'roi.dart';

const title = 'Native OpenCV Example';

Directory tempDir;
String get tempPath => '${tempDir.path}/temp.jpg';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  getTemporaryDirectory().then((dir) => tempDir = dir);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _isProcessed = false;
  bool _isWorking = false;
  String imageFilePath = "";
  String templateFilePath = "";
  String _extractText = '';
  List<Roi> roiList;

  void showVersion(BuildContext context) {
    final scaffoldState = Scaffold.of(context);
    final snackbar =
        SnackBar(content: Text('OpenCV version: ${opencvVersion()}'));

    scaffoldState
      ..removeCurrentSnackBar(reason: SnackBarClosedReason.dismiss)
      ..showSnackBar(snackbar);
  }

  Future<void> takeImage({bool isTemplate = false}) async {
    final image = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 100);
    setState(() {
      if (isTemplate) {
        templateFilePath = image.path;
      } else {
        imageFilePath = image.path;
      }
    });
  }

  Future<void> processAlignImages() async {
    setState(() {
      _isWorking = true;
    });

    // Creating a port for communication with isolate and arguments for entry point
    final port = ReceivePort();
    final args =
        ImageAlignmentArguments(imageFilePath, templateFilePath, tempPath);

    // Spawning an isolate
    Isolate.spawn<ImageAlignmentArguments>(alignImages, args,
        onError: port.sendPort, onExit: port.sendPort);

    // Making a variable to store a subscription in
    StreamSubscription sub;

    // Listeting for messages on port
    sub = port.listen((_) async {
      // Cancel a subscription after message received called
      await sub?.cancel();

      setState(() {
        _isProcessed = true;
        _isWorking = false;
      });
    });
  }

  String extractROI(Region region) {
    String roiImgPath = '${tempDir.path}/${region.id}.jpg';
    final args = ROIArguments(
        imagePath: tempPath,
        outputPath: roiImgPath,
        x: region.rect[0],
        y: region.rect[1],
        width: region.rect[2],
        height: region.rect[3]);
    extractROIImage(args);
    return roiImgPath;
    // final port = ReceivePort();
    // // Spawning an isolate
    // Isolate.spawn<ROIArguments>(extractROIImage, args,
    //     onError: port.sendPort, onExit: port.sendPort);

    // // Making a variable to store a subscription in
    // StreamSubscription sub;

    // // Listeting for messages on port
    // sub = port.listen((_) async {
    //   // Cancel a subscription after message received called
    //   await sub?.cancel();
    //   return
    // });
  }

  Future<String> roiImgToString(String roiImgPath) async {
    return await TesseractOcr.extractText(roiImgPath);
  }

  Future<void> imageToString() async {
    final image = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 100);
    if (image == null) {
      return;
    }

    _isWorking = true;
    setState(() {});

    _extractText = await TesseractOcr.extractText(image.path);
    _isWorking = false;
    setState(() {});
  }

  Future<void> takeImageAndProcess() async {
    final image = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 100);
    if (image == null) {
      return;
    }

    setState(() {
      _isWorking = true;
    });

    // Creating a port for communication with isolate and arguments for entry point
    final port = ReceivePort();
    final args = ProcessImageArguments(image.path, tempPath);

    // Spawning an isolate
    Isolate.spawn<ProcessImageArguments>(processImage, args,
        onError: port.sendPort, onExit: port.sendPort);

    // Making a variable to store a subscription in
    StreamSubscription sub;

    // Listeting for messages on port
    sub = port.listen((_) async {
      // Cancel a subscription after message received called
      await sub?.cancel();

      setState(() {
        _isProcessed = true;
        _isWorking = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Stack(
        children: <Widget>[
          Center(
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                Center(child: SelectableText(_extractText)),
                if (templateFilePath != '')
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 3000, maxHeight: 300),
                    child: Image.file(
                      File(templateFilePath),
                      alignment: Alignment.center,
                    ),
                  ),
                if (imageFilePath != '')
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 3000, maxHeight: 300),
                    child: Image.file(
                      File(imageFilePath),
                      alignment: Alignment.center,
                    ),
                  ),
                if (_isProcessed && !_isWorking)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 3000, maxHeight: 300),
                    child: Image.file(
                      File(tempPath),
                      alignment: Alignment.center,
                    ),
                  ),
                Builder(builder: (context) {
                  return RaisedButton(
                      child: Text('Show version'),
                      onPressed: () => showVersion(context));
                }),
                RaisedButton(
                    child: Text('Template photo'),
                    onPressed: () async => await takeImage(isTemplate: true)),
                RaisedButton(
                    child: Text('Image photo'),
                    onPressed: () => takeImage(isTemplate: false)),
                RaisedButton(
                    child: Text('Image Alignment'),
                    onPressed: processAlignImages),
                // RaisedButton(
                //     child: Text('Process photo'), onPressed: imageToString)
              ],
            ),
          ),
          if (_isWorking)
            Positioned.fill(
                child: Container(
              color: Colors.black.withOpacity(.7),
              child: Center(child: CircularProgressIndicator()),
            )),
        ],
      ),
    );
  }
}
