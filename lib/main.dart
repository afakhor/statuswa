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
          child: SingleChildScrollView(
            child: Globe3DWidget(),
          ),
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

  // Controller untuk menangkap running text dari pengguna
  final TextEditingController _textController =
      TextEditingController(text: 'BABE.INFO');

  Offset _touchOffset = Offset.zero;
  Offset _lastTouchOffset = Offset.zero;

  final String _baseUrl = 'https://afakhor.github.io/statuswa/';

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
    final program = await ui.FragmentProgram.fromAsset('shaders/globe.frag');
    final dynamicTexture = await generateRunningTextTexture(_textController.text);

    if (mounted) {
      setState(() {
        _program = program;
        _textureImage = dynamicTexture;
      });
    }
  }

  // Merender ulang tekstur bola saat teks diinputkan
  Future<void> _updateTexture(String newText) async {
    final textToRender = newText.trim().isEmpty ? 'BABE.INFO' : newText;
    final updatedTexture = await generateRunningTextTexture(textToRender);
    if (mounted) {
      setState(() {
        _textureImage = updatedTexture;
      });
    }
  }

  // Membagikan link beserta teks kustom ke WhatsApp
  void _shareToWhatsApp() {
    final inputMessage = _textController.text.trim();
    final customText = inputMessage.isEmpty ? 'BABE.INFO' : inputMessage;
    
    // Encode parameter agar aman digunakan di URL
    final encodedText = Uri.encodeComponent(customText);
    final dynamicUrl = '$_baseUrl?text=$encodedText';

    Share.share(
      'Coba putar bola 3D Emas "$customText" ini secara langsung di HP kamu:\n$dynamicUrl',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null || _textureImage == null) {
      return const CircularProgressIndicator(color: Colors.amber);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        // Area Interactive Globe 3D
        GestureDetector(
          onPanStart: (details) {
            _lastTouchOffset = details.localPosition;
          },
          onPanUpdate: (details) {
            setState(() {
              final delta = details.localPosition - _lastTouchOffset;
              _touchOffset += Offset(delta.dx * 0.01, -delta.dy * 0.01);
              _lastTouchOffset = details.localPosition;
            });
          },
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(300, 300),
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

        const SizedBox(height: 24),

        // Input Field untuk Teks Kustom
        TextField(
          controller: _textController,
          style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: 'Ketik Running Text',
            labelStyle: const TextStyle(color: Colors.amber),
            hintText: 'Misal: BABE.INFO / PUSAT BERITA',
            hintStyle: TextStyle(color: Colors.grey.shade600),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.amber),
              borderRadius: BorderRadius.circular(15),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.amberAccent, width: 2),
              borderRadius: BorderRadius.circular(15),
            ),
            prefixIcon: const Icon(Icons.text_fields, color: Colors.amber),
          ),
          onChanged: (val) => _updateTexture(val),
        ),

        const SizedBox(height: 20),

        // Tombol Share ke WhatsApp
        ElevatedButton.icon(
          onPressed: _shareToWhatsApp,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
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

    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, time);
    shader.setFloat(3, touch.dx);
    shader.setFloat(4, touch.dy);
    shader.setImageSampler(0, texture);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant GlobePainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.touch != touch ||
        oldDelegate.texture != texture;
  }
}

// Generator Tekstur Dinamis Berdasarkan Input Pengguna
Future<ui.Image> generateRunningTextTexture(String customText) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  const double width = 1024;
  const double height = 512;

  final paint = Paint()..color = Colors.transparent;
  canvas.drawRect(const Rect.fromLTWH(0, 0, width, height), paint);

  const textStyle = TextStyle(
    color: Color(0xFF111111),
    fontSize: 48,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
  );

  final textPainter = TextPainter(
    text: TextSpan(text: customText.toUpperCase(), style: textStyle),
    textDirection: TextDirection.ltr,
  )..layout();

  const double rowSpacing = 80;
  final double colSpacing = textPainter.width + 60;

  for (double y = 20; y < height; y += rowSpacing) {
    double xOffset = ((y / rowSpacing).floor() % 2 == 0) ? 0 : colSpacing / 2;
    for (double x = -100 + xOffset; x < width + 200; x += colSpacing) {
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  final picture = recorder.endRecording();
  return await picture.toImage(width.toInt(), height.toInt());
}
