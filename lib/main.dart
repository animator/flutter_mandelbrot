import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'complex.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hide android status bar for fullscreen experience
  SystemChrome.setEnabledSystemUIOverlays([]);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mandelbrot App',
      home: MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  IconData icon = Icons.play_arrow;

  bool paused = true;
  double width = ui.window.physicalSize.width / ui.window.devicePixelRatio;
  double height = ui.window.physicalSize.height / ui.window.devicePixelRatio;
  MandelbrotPainter painter;

  @override
  void initState() {
    painter = MandelbrotPainter(width.toInt(), height.toInt());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        constraints: BoxConstraints.expand(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              child: SizedBox(
                width: this.width,
                height: this.height,
                child: CustomPaint(
                  painter: painter,
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(icon, size: 25.0),
        onPressed: () {
          setState(() {
            painter.update();
            //paused = !paused;
            //icon = icon == Icons.pause ? Icons.play_arrow : Icons.pause;
          });
        },
      ),
    );
  }
}

class MandelbrotPainter extends CustomPainter {
  List<List<int>> _currentPixelIteration;
  List<List<Complex>> C, z;
  int _currentIter = 0;
  int get currentIter => _currentIter;
  int width;
  int height;

  MandelbrotPainter(int width, int height) {
    print("$width, $height");
    this.width = width;
    this.height = height;
    double wratio = 1;
    double hratio = 1;

    final ratio = width / height;
    if (ratio < 1) {
      hratio = hratio / ratio;
    } else {
      wratio = ratio;
    }

    C = List<List<Complex>>.generate(
        height,
        (y) => List<Complex>.generate(
            width,
            (x) => Complex(wratio * (3.0 * x / width - 2.25),
                hratio * (3.0 * y / height - 1.5))));
    z = List<List<Complex>>.generate(
        height, (y) => List<Complex>.generate(width, (x) => Complex(0, 0)));
    _currentPixelIteration = List<List<int>>.generate(
        height, (y) => List<int>.generate(width, (x) => 0));
  }

  void update() {
    _currentIter += 1;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        if (z[y][x].abs() < 2) {
          z[y][x] = z[y][x] * z[y][x] + C[y][x];
          _currentPixelIteration[y][x] += 1;
        }
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) async {
    // Define a paint object with 1 pixel stroke width
    if (_currentPixelIteration != null) {
      final paint = Paint()..strokeWidth = 1.0;
      int width =
          math.min(_currentPixelIteration[0].length, size.width.toInt());
      int height = math.min(_currentPixelIteration.length, size.height.toInt());

      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          var iter = _currentPixelIteration[y][x] + 1;
          // Convert threshold iteration into an RBG value for pixel color
          paint.color = Color.fromRGBO(
              255 * (1 + math.cos(3.32 * math.log(iter))) ~/ 2,
              255 * (1 + math.cos(0.774 * math.log(iter))) ~/ 2,
              255 * (1 + math.cos(0.412 * math.log(iter))) ~/ 2,
              1);
          // Paint the pixel on canvas
          canvas.drawPoints(ui.PointMode.points,
              <Offset>[Offset(x.toDouble(), y.toDouble())], paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(MandelbrotPainter oldDelegate) => true;
}
