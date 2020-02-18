import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:complex/complex.dart';
import 'package:provider/provider.dart';

// Maximum number of iterations 
// Keep the value = 2^n where n is a natural number
const int ITER_MAX = 32;

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

class MandelbrotClass extends ChangeNotifier {
  List<List<int>> _currentPixelIteration;
  int _currentIter = 0;

  List<List<int>> get pixelIter => _currentPixelIteration;
  int get currentIter => _currentIter;

  MandelbrotClass();

  void thresholdIterationList(int width, int height) async {
    double wratio = 1;
    double hratio = 1;

    final ratio = width / height;
    if (ratio < 1) {
      hratio = hratio / ratio;
    } else {
      wratio = ratio;
    }

    List<List<Complex>> C = List<List<Complex>>.generate(
      height,
      (y) => List<Complex>.generate(
        width,
        (x) => Complex(wratio * (3.0 * x / width - 2.25),
                       hratio * (3.0 * y / height - 1.5))
        )
      );
    List<List<Complex>> z = List<List<Complex>>.generate(
      height, 
      (y) => List<Complex>.generate(width, (x) => Complex(0, 0))
      );    
    List<List<bool>> continueIteration = List<List<bool>>.generate(
      height, 
      (y) => List<bool>.generate(width, (x) => true)
      );
    _currentPixelIteration = List<List<int>>.generate(
      height, 
      (y) => List<int>.generate(width, (x) => 0)
      );
    notifyListeners();

    for (int maxIter = 1; maxIter <= ITER_MAX; maxIter*=2) {
      await Future.delayed(Duration(seconds: 5));
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          if (continueIteration[y][x]) {
            var iter = _currentPixelIteration[y][x];
            while (iter <= maxIter && z[y][x].abs() < 2) {
              z[y][x] = z[y][x] * z[y][x] + C[y][x];
              iter = iter + 1;
            }
            if (iter <= maxIter) {
              continueIteration[y][x] = false;
            }
            _currentPixelIteration[y][x] = iter;
          }
        }
      }
      _currentIter = maxIter;
      notifyListeners();
    }
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    // Get the height and width of the screen
    int w = MediaQuery.of(context).size.width.toInt();
    int h = MediaQuery.of(context).size.height.toInt();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<MandelbrotClass>(
          create: (_) {
            return MandelbrotClass()
                    ..thresholdIterationList(w, h);
          } 
        ),
      ],
      child: Scaffold(
        body: Stack(
          children: <Widget>[ 
            // A container occupying the entire screen
            Container(
              width: double.infinity,
              height: double.infinity,
              color: Colors.white,
              // Creating a Consumer for MandelbrotClass 
              child: Consumer<MandelbrotClass>(
                builder: (_, mandelbrot, __) {
                  return CustomPaint(
                    painter: FractalPainter(
                      mandelbrot.pixelIter
                    ),
                  );
                } ,
              ),
            ),
            // Text displaying current max iterations at the 
            // bottom-left part of the screen
            Align(
              alignment: Alignment.bottomLeft,
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Consumer<MandelbrotClass>(
                  builder: (_, mandelbrot, __) {
                    return Text(
                      "Iterations - ${mandelbrot.currentIter}"
                      );
                  } ,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FractalPainter extends CustomPainter {
  FractalPainter(this.renderPoints);
  final List<List<int>> renderPoints;

  @override
  void paint(Canvas canvas, Size size) async {
    // Define a paint object with 1 pixel stroke width
    if(renderPoints != null){
      final paint = Paint()..strokeWidth = 1.0;
      int width = math.min(renderPoints[0].length, size.width.toInt());
      int height = math.min(renderPoints.length, size.height.toInt());

      for (int x = 0; x < width; x++) {
        for (int y = 0; y < height; y++) {
          var iter = renderPoints[y][x]+1;
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
  bool shouldRepaint(FractalPainter oldDelegate) => true;
}
