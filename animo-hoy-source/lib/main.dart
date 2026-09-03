import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const AnimoHoyApp());

class AnimoHoyApp extends StatelessWidget {
  const AnimoHoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ánimo Hoy',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF6C63E8)),
      home: const MoodHome(),
    );
  }
}

class Mood {
  const Mood(this.name, this.emoji, this.color, this.soft, this.messages);
  final String name;
  final String emoji;
  final Color color;
  final Color soft;
  final List<String> messages;
}

const moods = <Mood>[
  Mood('Feliz', '😄', Color(0xFFFFA726), Color(0xFFFFE0B2), [
    'Disfruta este momento. Tu alegría también puede iluminar a alguien más.',
    'Celebra lo bueno, aunque parezca pequeño. También cuenta.',
    'Sigue haciendo espacio para las cosas que te hacen sonreír.',
  ]),
  Mood('Tranquilo', '😌', Color(0xFF26A69A), Color(0xFFB2DFDB), [
    'Respira y disfruta la calma. No todo tiene que resolverse hoy.',
    'Estar en paz también es avanzar.',
    'Tu calma es un buen lugar para ordenar tus ideas.',
  ]),
  Mood('Normal', '🙂', Color(0xFF42A5F5), Color(0xFFBBDEFB), [
    'No todos los días tienen que ser extraordinarios. Seguir adelante ya cuenta.',
    'Un paso pequeño sigue siendo un paso hacia adelante.',
    'Todavía queda tiempo para que algo bonito ocurra hoy.',
  ]),
  Mood('Triste', '😔', Color(0xFF6678B8), Color(0xFFC5CAE9), [
    'Un momento difícil no define todo tu día. Ve paso a paso.',
    'Sé amable contigo hoy. No necesitas resolverlo todo de una sola vez.',
    'Un día pesado también termina. Cuídate mientras pasa.',
  ]),
  Mood('Ansioso', '😟', Color(0xFF8E6CC7), Color(0xFFD1C4E9), [
    'Una cosa a la vez: una respiración, un paso y luego el siguiente.',
    'No tienes que solucionar todo ahora. Concéntrate solo en lo que sigue.',
    'Inhala despacio, exhala aún más despacio y vuelve al presente.',
  ]),
  Mood('Cansado', '😴', Color(0xFF78909C), Color(0xFFCFD8DC), [
    'Descansar también es parte del progreso.',
    'No tienes que rendir al máximo todos los días. Date un respiro.',
    'A veces avanzar significa detenerse un momento para recuperar energía.',
  ]),
];

class MoodHome extends StatefulWidget {
  const MoodHome({super.key});
  @override
  State<MoodHome> createState() => _MoodHomeState();
}

class _MoodHomeState extends State<MoodHome> {
  final random = Random();
  Mood? selected;
  String? message;
  int version = 0;

  Future<void> choose(Mood mood) async {
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.lightImpact();
    setState(() {
      selected = mood;
      message = mood.messages[random.nextInt(mood.messages.length)];
      version++;
    });
  }

  Future<void> another() async {
    if (selected == null) return;
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.selectionClick();
    String next;
    do {
      next = selected!.messages[random.nextInt(selected!.messages.length)];
    } while (next == message && selected!.messages.length > 1);
    setState(() {
      message = next;
      version++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mood = selected;
    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [mood?.color ?? const Color(0xFF6C63E8), mood?.soft ?? const Color(0xFFD9D5FF)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Row(
                  children: [
                    Text('✨', style: TextStyle(fontSize: 30)),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ánimo Hoy', style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
                        Text('Un pequeño momento para ti', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 420),
                    child: mood == null ? picker() : result(mood),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget picker() => Container(
        key: const ValueKey('picker'),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 30, offset: Offset(0, 16))],
        ),
        child: Column(
          children: [
            const Text('¿Cómo te sientes hoy?', textAlign: TextAlign.center, style: TextStyle(fontSize: 27, fontWeight: FontWeight.w900)),
            const SizedBox(height: 7),
            const Text('Toca el emoji que mejor represente tu momento', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
            const SizedBox(height: 22),
            Expanded(
              child: GridView.builder(
                itemCount: moods.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.25),
                itemBuilder: (_, i) {
                  final mood = moods[i];
                  return Material(
                    color: mood.soft.withValues(alpha: .55),
                    borderRadius: BorderRadius.circular(22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(22),
                      onTap: () => choose(mood),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(mood.emoji, style: const TextStyle(fontSize: 50)),
                          const SizedBox(height: 6),
                          Text(mood.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: mood.color)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const Text('Reconocer cómo te sientes ya es un buen comienzo.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 12.5)),
          ],
        ),
      );

  Widget result(Mood mood) => Container(
        key: ValueKey('result-${mood.name}'),
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .95),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 30, offset: Offset(0, 16))],
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() { selected = null; message = null; }),
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Cambiar emoción'),
              ),
            ),
            const Spacer(),
            TweenAnimationBuilder<double>(
              key: ValueKey('emoji-$version'),
              tween: Tween(begin: .55, end: 1),
              duration: const Duration(milliseconds: 650),
              curve: Curves.elasticOut,
              builder: (_, value, child) => Transform.scale(scale: value, child: child),
              child: Text(mood.emoji, style: const TextStyle(fontSize: 98)),
            ),
            Text('Te sientes ${mood.name.toLowerCase()}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: mood.color)),
            const SizedBox(height: 22),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              child: Container(
                key: ValueKey('$version-$message'),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: mood.soft.withValues(alpha: .50), borderRadius: BorderRadius.circular(24)),
                child: Text(message!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.45)),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: another,
                style: FilledButton.styleFrom(backgroundColor: mood.color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18))),
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Otra frase', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Bienestar general. No sustituye orientación profesional.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black45, fontSize: 11.5)),
          ],
        ),
      );
}
