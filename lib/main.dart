import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '3D Gold Globe',
      theme: ThemeData.dark(),
      home: const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Globe3DWidget(),
        ),
      ),
    );
  }
}

class Globe3DWidget extends StatefulWidget {
  const Globe3DWidget({super.key});

  @override
  State<Globe3DWidget> createState() => _Globe3DWidgetState();
}

class _Globe3DWidgetState extends State<Globe3DWidget>
    with SingleTickerProviderStateMixin {
  ui.FragmentProgram? _program;
  ui.Image? _textureImage;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _initShaderAndTexture();
  }

  Future<void> _initShaderAndTexture() async {
    // 1. Load Fragment Shader
    final program = await ui.FragmentProgram.fromAsset('shaders/globe.frag');
    
    // 2. Generate Tekstur BABE.INFO secara prosedural di Dart
    final dynamicTexture = await generateBabeInfoTexture();

    if (mounted) {
      setState(() {
        _program = program;
        _textureImage = dynamicTexture;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null || _textureImage == null) {
      return const CircularProgressIndicator(color: Colors.amber);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(320, 320),
          painter: GlobePainter(
            program: _program!,
            texture: _textureImage!,
            time: _controller.value * 2 * 3.14159265359,
          ),
        );
      },
    );
  }
}

class GlobePainter extends CustomPainter {
  final ui.FragmentProgram program;
  final ui.Image texture;
  final double time;

  GlobePainter({
    required this.program,
    required this.texture,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // Uniform 0 & 1: uResolution (width, height)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // Uniform 2: uTime
    shader.setFloat(2, time);

    // Sampler2D 0: uTexture
    shader.setImageSampler(0, texture);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant GlobePainter oldDelegate) {
    return oldDelegate.time != time;
  }
}

// Helper untuk membuat tekstur teks "BABE.INFO"
Future<ui.Image> generateBabeInfoTexture() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const double width = 1024;
  const double height = 512;

  final paint = Paint()..color = Colors.transparent;
  canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), paint);

  const textStyle = TextStyle(
    color: Color(0xFF111111),
    fontSize: 52,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
  );

  final textPainter = TextPainter(
    text: const TextSpan(text: 'BABE.INFO', style: textStyle),
    textDirection: TextDirection.ltr,
  )..layout();

  const double rowSpacing = 80;
  const double colSpacing = 320;

  for (double y = 20; y < height; y += rowSpacing) {
    double xOffset = ((y / rowSpacing).floor() % 2 == 0) ? 0 : 120;
    for (double x = -100 + xOffset; x < width + 100; x += colSpacing) {
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  final picture = recorder.endRecording();
  return await picture.toImage(width.toInt(), height.toInt());
}
