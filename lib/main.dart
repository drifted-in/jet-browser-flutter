import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

void main(List<String> args) {
  runApp(MyApp(args[0]));
}

class MyApp extends StatelessWidget {

  final String archiveFilePath;

  const MyApp(
    this.archiveFilePath
  );

  @override
  Widget build(BuildContext context) {

    final File file = new File(archiveFilePath);
    Archive archive = ZipDecoder().decodeBytes(file.readAsBytesSync());

    List<String> filePathList = archive
        .where((archiveFile) => (archiveFile.isFile && archiveFile.name.toLowerCase().endsWith(".jpg")))
        .map((archiveFile) => archiveFile.name)
        .toList();

    Map<int, String> filePathMap = filePathList.asMap();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyHomePage(
          archive: archive,
          filePathMap: filePathMap
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {

  final Archive archive;
  final Map<int, String> filePathMap;

  const MyHomePage({
    Key key,
    @required this.archive,
    @required this.filePathMap,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();

}

class _MyHomePageState extends State<MyHomePage> {

  String filePath;
  ArchiveFile archiveFile;
  Image image;
  Size widgetSize;
  TransformationController transformationController;
  int currentImageIndex;
  FocusNode focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    updateImage(0);
  }

  void updateImage(int index) {
    currentImageIndex = index;
    filePath = widget.filePathMap[index];
    archiveFile = widget.archive.findFile(filePath);
    var imageData = new MemoryImage(archiveFile.content);
    imageData
        .resolve(ImageConfiguration())
        .addListener(ImageStreamListener((ImageInfo _, bool __) {
      if (mounted) {
        setState(() {
          image = new Image(image: imageData);
        });
      }
    }));
  }

  void updateWidgetSize(Size widgetSize) {
    setState(() {
      this.widgetSize = widgetSize;
    });
  }

  void initTransformationController() async {

    Matrix4 matrix = await getMatrix(BoxFit.fitHeight);

    setState(() {
      transformationController = new TransformationController(matrix);
    });
  }

  Future<Matrix4> getMatrix(BoxFit fit) async {

    Matrix4 matrix = Matrix4.identity();

    if (fit == BoxFit.fitHeight || fit == BoxFit.fitWidth) {

      double scale = 1.0;
      ui.Image image = await decodeImageFromList(archiveFile.content);

      if (fit == BoxFit.fitHeight) {
        scale = widgetSize.height / image.height;
      } else if (fit == BoxFit.fitWidth) {
        scale = widgetSize.width / image.width;
      }

      if (scale != 1.0) {
        matrix.scale(scale);
      }
    }

    return matrix;
  }

  void handleKey(RawKeyEvent keyEvent) async {

    if (keyEvent.isKeyPressed(LogicalKeyboardKey.arrowLeft) ||
        keyEvent.isKeyPressed(LogicalKeyboardKey.arrowRight) ||
        keyEvent.isKeyPressed(LogicalKeyboardKey.home) ||
        keyEvent.isKeyPressed(LogicalKeyboardKey.end)) {

      int newImageIndex = currentImageIndex;

      if (keyEvent.isKeyPressed(LogicalKeyboardKey.home)) {
        newImageIndex = 0;
      } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.end)) {
        newImageIndex = widget.filePathMap.length - 1;
      } else {
        int delta = keyEvent.isControlPressed ? 20 : (keyEvent.isShiftPressed ? 5 : 1);

        if (keyEvent.isKeyPressed(LogicalKeyboardKey.arrowLeft)) {
          newImageIndex = max(currentImageIndex - delta, 0);
        } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.arrowRight)) {
          newImageIndex = min(currentImageIndex + delta, widget.filePathMap.length - 1);
        }
      }

      if (newImageIndex != currentImageIndex) {
        updateImage(newImageIndex);
      }
    } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.keyW)) {
      Matrix4 matrix = await getMatrix(BoxFit.fitWidth);
      setState(() {
        transformationController = new TransformationController(matrix);
      });
    } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.keyH)) {
      Matrix4 matrix = await getMatrix(BoxFit.fitHeight);
      setState(() {
        transformationController = new TransformationController(matrix);
      });
    } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.keyR)) {
      setState(() {
        transformationController = new TransformationController(Matrix4.identity());
      });
    } else if (keyEvent.isKeyPressed(LogicalKeyboardKey.keyC)) {
      Clipboard.setData(new ClipboardData(text: filePath));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: RawKeyboardListener(
          focusNode: focusNode,
          autofocus: true,
          onKey: handleKey,
          child: WidgetSize(
            onChange: (Size widgetSize) {
              updateWidgetSize(widgetSize);
              if (transformationController == null) {
                initTransformationController();
              }
            },
            child: InteractiveViewer(
              transformationController: transformationController,
              constrained: false,
              maxScale: 5.0,
              minScale: 0.01,
              boundaryMargin: EdgeInsets.all(double.infinity),
              child: (transformationController == null) ? Container() : image,
            ),
          ),
        ),
      ),
    );
  }
}

class WidgetSize extends StatefulWidget {

  final Widget child;
  final Function onChange;

  const WidgetSize({
    Key key,
    @required this.onChange,
    @required this.child,
  }) : super(key: key);

  @override
  _WidgetSizeState createState() => _WidgetSizeState();
}

class _WidgetSizeState extends State<WidgetSize> {
  @override
  Widget build(BuildContext context) {
    SchedulerBinding.instance.addPostFrameCallback(postFrameCallback);
    return Container(
      key: widgetKey,
      child: widget.child,
    );
  }

  var widgetKey = GlobalKey();
  var oldSize;

  void postFrameCallback(_) {
    var context = widgetKey.currentContext;
    if (context == null) return;

    var newSize = context.size;
    if (oldSize == newSize) return;

    oldSize = newSize;
    widget.onChange(newSize);
  }
}