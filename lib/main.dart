import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

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

  // Variabel penampung gesture sentuhan jari (Touch/Drag)
  Offset _touchOffset = Offset.zero;
  Offset _lastTouchOffset = Offset.zero;

  // SESUAIKAN DENGAN USERNAME & REPO GITHUB KAMU
  final String _webAppUrl = 'https://username.github.io/statuswa/';

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

    // 2. Generate Tekstur BABE.INFO secara prosedural
    final dynamicTexture = await generateBabeInfoTexture();

    if (mounted) {
      setState(() {
        _program = program;
        _textureImage = dynamicTexture;
      });
    }
  }

  // Fungsi untuk membagikan Link Web Interaktif ke WhatsApp
  void _shareToWhatsApp() {
    Share.share(
      'Coba putar bola 3D Emas BABE.INFO ini secara langsung di HP kamu:\n$_webAppUrl',
    );
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Area Interactive Globe 3D
        GestureDetector(
          onPanStart: (details) {
            _lastTouchOffset = details.localPosition;
          },
          onPanUpdate: (details) {
            setState(() {
              // Hitung jarak geseran jari pengguna untuk memutar bola
              final delta = details.localPosition - _lastTouchOffset;
              _touchOffset += Offset(delta.dx * 0.01, -delta.dy * 0.01);
              _lastTouchOffset = details.localPosition;
            });
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(320, 320),
                painter: GlobePainter(
                  program: _program!,
                  texture: _textureImage!,
                  time: _controller.value * 2 * 3.14159265359,
                  touch: _touchOffset,
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 32),

        // Tombol Share ke WhatsApp
        ElevatedButton.icon(
          onPressed: _shareToWhatsApp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366), // Warna Khas WhatsApp
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            elevation: 4,
          ),
          icon: const Icon(Icons.share, size: 20),
          label: const Text(
            'Bagikan ke WhatsApp',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class GlobePainter extends CustomPainter {
  final ui.FragmentProgram program;
  final ui.Image texture;
  final double time;
  final Offset touch;

  GlobePainter({
    required this.program,
    required this.texture,
    required this.time,
    required this.touch,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shader = program.fragmentShader();

    // Uniform 0 & 1: uResolution (Width & Height)
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);

    // Uniform 2: uTime (Waktu animasi)
    shader.setFloat(2, time);

    // Uniform 3 & 4: uTouch (Offset X & Y sentuhan jari)
    shader.setFloat(3, touch.dx);
    shader.setFloat(4, touch.dy);

    // Sampler2D 0: uTexture (Tekstur BABE.INFO)
    shader.setImageSampler(0, texture);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant GlobePainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.touch != touch;
  }
}

// Helper Generator Tekstur "BABE.INFO"
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
