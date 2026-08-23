import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.black12,
        body: Center(child: GlobeShaderWidget()),
      ),
    );
  }
}

class GlobeShaderWidget extends StatefulWidget {
  const GlobeShaderWidget({super.key});

  @override
  State<GlobeShaderWidget> createState() => _GlobeShaderWidgetState();
}

class _GlobeShaderWidgetState extends State<GlobeShaderWidget>
    with SingleTickerProviderStateMixin {
  ui.FragmentShader? _shader;
  ui.Image? _textureImage;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _loadShaderAndTexture();
  }

  Future<void> _loadShaderAndTexture() async {
    // 1. Load Fragment Shader
    final program = await ui.FragmentProgram.fromAsset('shaders/globe.frag');
    
    // 2. Load Gambar Tekstur dari Assets
    final ByteData data = await rootBundle.load('assets/images/babe_gold.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();

    setState(() {
      _shader = program.fragmentShader();
      _textureImage = frame.image;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _shader?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_shader == null || _textureImage == null) {
      return const CircularProgressIndicator();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(350, 350),
          painter: GlobePainter(
            shader: _shader!,
            texture: _textureImage!,
            time: _controller.value * 2 * 3.14159, // Rotasi 360 derajat
          ),
        );
      },
    );
  }
}

class GlobePainter extends CustomPainter {
  final ui.FragmentShader shader;
  final ui.Image texture;
  final double time;

  GlobePainter({
    required this.shader,
    required this.texture,
    required this.time,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Set Uniforms untuk Shader GLSL:
    // Index 0: uResolution.x
    // Index 1: uResolution.y
    // Index 2: uTime
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);

    // Set Sampler0: uTexture (Gambar Tekstur)
    shader.setImageSampler(0, texture);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant GlobePainter oldDelegate) => true;
}
