import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AnimoHoyApp());
}

class AnimoHoyApp extends StatelessWidget {
  const AnimoHoyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ánimo Hoy',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF7867E8),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F5FF),
      ),
      home: const HomePage(),
    );
  }
}

enum MotiFace { happy, calm, neutral, sad, anxious, sleepy, excited }

class Mood {
  const Mood({
    required this.label,
    required this.emoji,
    required this.face,
    required this.color,
    required this.soft,
    required this.messages,
    required this.missions,
  });

  final String label;
  final String emoji;
  final MotiFace face;
  final Color color;
  final Color soft;
  final List<String> messages;
  final List<String> missions;
}

const moodItems = <Mood>[
  Mood(
    label: 'Feliz',
    emoji: '😄',
    face: MotiFace.happy,
    color: Color(0xFFFFA93A),
    soft: Color(0xFFFFE8B8),
    messages: [
      '¡Me encanta verte así! Guarda un poquito de esta alegría para más tarde.',
      'Hoy hay algo bonito pasando. Disfrútalo sin sentir que tienes que correr.',
      'Tu sonrisa cuenta. ¿Compartimos un poquito de esa energía con alguien?',
    ],
    missions: [
      'Escríbele algo bonito a una persona.',
      'Anota una cosa buena que pasó hoy.',
      'Pon una canción que te haga sonreír.',
    ],
  ),
  Mood(
    label: 'Tranquilo',
    emoji: '😌',
    face: MotiFace.calm,
    color: Color(0xFF2DB5A5),
    soft: Color(0xFFBFEDE7),
    messages: [
      'Qué bien se siente un momento sin prisa. Me quedo aquí contigo.',
      'No necesitas llenar cada minuto. La calma también es productiva.',
      'Aprovechemos esta pausa para respirar y agradecer algo sencillo.',
    ],
    missions: [
      'Respira conmigo durante 30 segundos.',
      'Toma un vaso de agua sin mirar el celular.',
      'Quédate un minuto en silencio.',
    ],
  ),
  Mood(
    label: 'Normal',
    emoji: '🙂',
    face: MotiFace.neutral,
    color: Color(0xFF4E9EF4),
    soft: Color(0xFFCBE4FF),
    messages: [
      'No todos los días tienen que ser increíbles. Estar aquí ya cuenta.',
      'Podemos hacer una cosita pequeña para que el día se sienta un poco mejor.',
      'Un día normal también puede guardar algo bueno. Vamos a encontrarlo.',
    ],
    missions: [
      'Camina cinco minutos.',
      'Ordena un espacio pequeño.',
      'Haz algo que hayas estado posponiendo por menos de 5 minutos.',
    ],
  ),
  Mood(
    label: 'Triste',
    emoji: '😔',
    face: MotiFace.sad,
    color: Color(0xFF7183C7),
    soft: Color(0xFFD8DFF7),
    messages: [
      'Hoy parece pesado. No tienes que arreglarlo todo; me quedo contigo un momento.',
      'Vamos despacio. Tu única tarea ahora puede ser cuidarte un poquito.',
      'No voy a pedirte que sonrías. Solo que hagamos juntos el siguiente paso pequeño.',
    ],
    missions: [
      'Respira conmigo durante 30 segundos.',
      'Escribe una sola frase sobre lo que necesitas ahora.',
      'Haz algo amable por ti: agua, descanso o una ducha tranquila.',
    ],
  ),
  Mood(
    label: 'Ansioso',
    emoji: '😟',
    face: MotiFace.anxious,
    color: Color(0xFF9568D9),
    soft: Color(0xFFE1D2F5),
    messages: [
      'Una cosa a la vez. No necesitamos resolver mañana en este minuto.',
      'Mírame un segundo. Inhala lento… y suelta el aire todavía más lento.',
      'Volvamos al presente: aquí, ahora, solo el siguiente paso.',
    ],
    missions: [
      'Haz la respiración guiada de 30 segundos.',
      'Nombra 3 cosas que ves a tu alrededor.',
      'Deja el celular boca abajo durante 5 minutos.',
    ],
  ),
  Mood(
    label: 'Cansado',
    emoji: '😴',
    face: MotiFace.sleepy,
    color: Color(0xFF728995),
    soft: Color(0xFFD6E0E4),
    messages: [
      'Tu energía no es infinita. Descansar también forma parte del progreso.',
      'Hoy podemos bajar un poco el ritmo. No tienes que poder con todo.',
      'Hagamos espacio para recuperar energía sin sentir culpa.',
    ],
    missions: [
      'Cierra los ojos durante un minuto.',
      'Toma agua y estira hombros y cuello.',
      'Elige una tarea que pueda esperar hasta mañana.',
    ],
  ),
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  final _random = Random();
  Mood? _selected;
  String _message = '¡Hola! Soy Moti. ¿Cómo estamos hoy?';
  String _mission = 'Elige cómo te sientes y te acompaño.';
  int _stars = 0;
  bool _missionDone = false;

  late final AnimationController _floatController;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _float = Tween<double>(begin: -4, end: 5).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  Future<void> _choose(Mood mood) async {
    await SystemSound.play(SystemSoundType.click);
    await HapticFeedback.lightImpact();
    setState(() {
      _selected = mood;
      _message = mood.messages[_random.nextInt(mood.messages.length)];
      _mission = mood.missions[_random.nextInt(mood.missions.length)];
      _missionDone = false;
      _stars += 5;
    });
  }

  void _newMessage() {
    final mood = _selected;
    if (mood == null) return;
    HapticFeedback.selectionClick();
    setState(() {
      String next;
      do {
        next = mood.messages[_random.nextInt(mood.messages.length)];
      } while (next == _message && mood.messages.length > 1);
      _message = next;
    });
  }

  void _completeMission() {
    if (_selected == null || _missionDone) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _missionDone = true;
      _stars += 10;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mood = _selected;
    final accent = mood?.color ?? const Color(0xFF7867E8);
    final face = mood?.face ?? MotiFace.excited;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hola 👋',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF777184),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Ánimo Hoy',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.8,
                              color: Color(0xFF25202B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _Pill(
                      icon: '⭐',
                      label: '$_stars',
                      background: const Color(0xFFFFF1C7),
                    ),
                    const SizedBox(width: 8),
                    const _Pill(
                      icon: '🔥',
                      label: '1',
                      background: Color(0xFFFFE1DA),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        accent.withValues(alpha: .98),
                        Color.lerp(accent, Colors.white, .42)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: .23),
                        blurRadius: 28,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      const Positioned(
                        right: -38,
                        top: -38,
                        child: _SoftOrb(size: 150, opacity: .14),
                      ),
                      const Positioned(
                        left: -50,
                        bottom: -65,
                        child: _SoftOrb(size: 170, opacity: .10),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: .18),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('🌱', style: TextStyle(fontSize: 16)),
                                      SizedBox(width: 5),
                                      Text(
                                        'Tu compañero: Moti',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  onPressed: () => _showAbout(context),
                                  style: IconButton.styleFrom(
                                    backgroundColor:
                                        Colors.white.withValues(alpha: .16),
                                    foregroundColor: Colors.white,
                                  ),
                                  icon: const Icon(Icons.info_outline_rounded),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            AnimatedBuilder(
                              animation: _float,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(0, _float.value),
                                child: child,
                              ),
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 360),
                                transitionBuilder: (child, animation) =>
                                    ScaleTransition(scale: animation, child: child),
                                child: Moti(
                                  key: ValueKey(face),
                                  face: face,
                                  accent: accent,
                                  size: 190,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                key: ValueKey(_message),
                                width: double.infinity,
                                padding: const EdgeInsets.fromLTRB(16, 13, 16, 14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .94),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      _message,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 15.5,
                                        height: 1.4,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF302B36),
                                      ),
                                    ),
                                    if (_selected != null) ...[
                                      const SizedBox(height: 4),
                                      TextButton.icon(
                                        onPressed: _newMessage,
                                        icon: const Icon(Icons.auto_awesome_rounded,
                                            size: 17),
                                        label: const Text('Otra frase'),
                                        style: TextButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 9),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        '¿Cómo te sientes?',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -.35,
                        ),
                      ),
                    ),
                    Text(
                      _selected == null ? 'Elige una' : _selected!.label,
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 100,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: moodItems.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final item = moodItems[index];
                    final selected = item == _selected;
                    return _MoodChip(
                      mood: item,
                      selected: selected,
                      onTap: () => _choose(item),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 17, 20, 0),
                child: _MissionCard(
                  accent: accent,
                  enabled: _selected != null,
                  done: _missionDone,
                  mission: _mission,
                  onDone: _completeMission,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                child: Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.air_rounded,
                        title: 'Respirar',
                        subtitle: '30 segundos',
                        color: const Color(0xFF59B5A8),
                        onTap: () => _showBreathing(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.edit_note_rounded,
                        title: 'Contarlo',
                        subtitle: 'Próximamente',
                        color: const Color(0xFF8D74D8),
                        onTap: () => _showSoon(context, 'Diario emocional'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBreathing(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _BreathingSheet(),
    );
  }

  void _showSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature estará en la versión completa.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Conoce a Moti 🌱',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            SizedBox(height: 10),
            Text(
              'Moti es tu pequeño compañero de Ánimo Hoy. Reacciona a cómo te sientes y te propone una acción sencilla para acompañarte.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'Esta es una versión de prueba. Las frases son de bienestar general y no sustituyen orientación profesional.',
              style: TextStyle(fontSize: 13, height: 1.45, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.icon,
    required this.label,
    required this.background,
  });

  final String icon;
  final String label;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 15)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _MoodChip extends StatelessWidget {
  const _MoodChip({
    required this.mood,
    required this.selected,
    required this.onTap,
  });

  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 180),
      scale: selected ? 1.04 : 1,
      child: Material(
        color: selected ? mood.soft : Colors.white,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 78,
            padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: selected ? mood.color : const Color(0xFFE9E5EF),
                width: selected ? 2 : 1,
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: mood.color.withValues(alpha: .14),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 34)),
                const SizedBox(height: 4),
                Text(
                  mood.label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: selected ? mood.color : const Color(0xFF58515F),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({
    required this.accent,
    required this.enabled,
    required this.done,
    required this.mission,
    required this.onDone,
  });

  final Color accent;
  final bool enabled;
  final bool done;
  final String mission;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFEDE9F2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D261B35),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: enabled
                  ? accent.withValues(alpha: .12)
                  : const Color(0xFFF1EEF4),
              borderRadius: BorderRadius.circular(17),
            ),
            alignment: Alignment.center,
            child: Text(done ? '🎉' : '✨', style: const TextStyle(fontSize: 25)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  done ? '¡Misión cumplida!' : 'Misión de Moti',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  done ? 'Ganaste 10 ⭐. Pequeño paso, gran cuenta.' : mission,
                  style: TextStyle(
                    height: 1.35,
                    fontSize: 13,
                    color: enabled
                        ? const Color(0xFF635C68)
                        : const Color(0xFFA09AA5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: enabled && !done ? onDone : null,
            style: IconButton.styleFrom(
              backgroundColor: done ? const Color(0xFF3CB990) : accent,
              foregroundColor: Colors.white,
              disabledBackgroundColor: done
                  ? const Color(0xFF3CB990)
                  : const Color(0xFFE5E0E9),
              disabledForegroundColor: Colors.white,
            ),
            icon: Icon(done ? Icons.check_rounded : Icons.arrow_forward_rounded),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(23),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(23),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(23),
            border: Border.all(color: const Color(0xFFEDE9F2)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF918A97), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BreathingSheet extends StatefulWidget {
  const _BreathingSheet();

  @override
  State<_BreathingSheet> createState() => _BreathingSheetState();
}

class _BreathingSheetState extends State<_BreathingSheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;
  int _seconds = 30;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_seconds <= 1) {
        timer.cancel();
        setState(() => _seconds = 0);
        HapticFeedback.mediumImpact();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 50),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFF7F5FF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xFFD5CFDD),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Respiremos con Moti',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 5),
            Text(
              _seconds == 0
                  ? 'Listo. Quédate un momento con esta calma.'
                  : 'Sigue el movimiento y respira sin apurarte.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF817987), fontSize: 14),
            ),
            const SizedBox(height: 26),
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final t = Curves.easeInOut.transform(_controller.value);
                final scale = .78 + (.22 * t);
                final label = _controller.value < .5 ? 'Inhala' : 'Exhala';
                return Column(
                  children: [
                    Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF8D7AEB), Color(0xFF67C9BC)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x308D7AEB),
                              blurRadius: 34,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Moti(
                          face: MotiFace.calm,
                          accent: const Color(0xFF7867E8),
                          size: 126,
                        ),
                      ),
                    ),
                    const SizedBox(height: 19),
                    Text(
                      _seconds == 0 ? 'Muy bien 💜' : label,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF6558C7),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              _seconds == 0 ? '✓' : '$_seconds s',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(_seconds == 0 ? 'Volver' : 'Terminar por ahora'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftOrb extends StatelessWidget {
  const _SoftOrb({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class Moti extends StatelessWidget {
  const Moti({
    super.key,
    required this.face,
    required this.accent,
    this.size = 180,
  });

  final MotiFace face;
  final Color accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _MotiPainter(face: face, accent: accent),
    );
  }
}

class _MotiPainter extends CustomPainter {
  _MotiPainter({required this.face, required this.accent});

  final MotiFace face;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * .57);
    final bodyRect = Rect.fromCenter(
      center: center,
      width: w * .66,
      height: h * .62,
    );

    final shadow = Paint()
      ..color = const Color(0x22000000)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w / 2, h * .91),
        width: w * .48,
        height: h * .09,
      ),
      shadow,
    );

    final leafPaint = Paint()..color = const Color(0xFF66C887);
    final leafDark = Paint()
      ..color = const Color(0xFF42A96B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .018
      ..strokeCap = StrokeCap.round;
    final leaf = Path()
      ..moveTo(w * .51, h * .25)
      ..cubicTo(w * .61, h * .08, w * .75, h * .12, w * .69, h * .28)
      ..cubicTo(w * .64, h * .38, w * .55, h * .34, w * .51, h * .25)
      ..close();
    canvas.drawPath(leaf, leafPaint);
    canvas.drawPath(
      Path()
        ..moveTo(w * .53, h * .27)
        ..quadraticBezierTo(w * .61, h * .21, w * .68, h * .18),
      leafDark,
    );
    canvas.drawLine(Offset(w * .5, h * .34), Offset(w * .53, h * .25), leafDark);

    final body = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(accent, Colors.white, .18)!,
          Color.lerp(accent, const Color(0xFF5C43BC), .30)!,
        ],
      ).createShader(bodyRect);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bodyRect, Radius.circular(w * .25)),
      body,
    );

    final shine = Paint()..color = Colors.white.withValues(alpha: .15);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .40, h * .44),
        width: w * .17,
        height: h * .13,
      ),
      shine,
    );

    final facePaint = Paint()
      ..color = const Color(0xFF312846)
      ..strokeWidth = w * .024
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final fillFace = Paint()
      ..color = const Color(0xFF312846)
      ..style = PaintingStyle.fill;

    final blush = Paint()..color = const Color(0xFFFFA4B6).withValues(alpha: .62);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .37, h * .64),
        width: w * .09,
        height: h * .045,
      ),
      blush,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * .63, h * .64),
        width: w * .09,
        height: h * .045,
      ),
      blush,
    );

    switch (face) {
      case MotiFace.happy:
      case MotiFace.excited:
        _arcEye(canvas, Offset(w * .41, h * .55), w * .045, true, facePaint);
        _arcEye(canvas, Offset(w * .59, h * .55), w * .045, true, facePaint);
        final smile = Path()
          ..moveTo(w * .43, h * .64)
          ..quadraticBezierTo(w * .50, h * .72, w * .58, h * .64);
        canvas.drawPath(smile, facePaint);
        if (face == MotiFace.excited) {
          final spark = Paint()
            ..color = Colors.white.withValues(alpha: .9)
            ..strokeWidth = w * .013
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(Offset(w * .73, h * .44), Offset(w * .73, h * .35), spark);
          canvas.drawLine(Offset(w * .69, h * .395), Offset(w * .77, h * .395), spark);
        }
        break;
      case MotiFace.calm:
        _arcEye(canvas, Offset(w * .41, h * .56), w * .045, true, facePaint);
        _arcEye(canvas, Offset(w * .59, h * .56), w * .045, true, facePaint);
        canvas.drawLine(Offset(w * .47, h * .66), Offset(w * .54, h * .66), facePaint);
        break;
      case MotiFace.neutral:
        canvas.drawCircle(Offset(w * .41, h * .56), w * .024, fillFace);
        canvas.drawCircle(Offset(w * .59, h * .56), w * .024, fillFace);
        canvas.drawLine(Offset(w * .46, h * .67), Offset(w * .54, h * .67), facePaint);
        break;
      case MotiFace.sad:
        _arcEye(canvas, Offset(w * .41, h * .57), w * .045, false, facePaint);
        _arcEye(canvas, Offset(w * .59, h * .57), w * .045, false, facePaint);
        final sad = Path()
          ..moveTo(w * .44, h * .69)
          ..quadraticBezierTo(w * .50, h * .63, w * .56, h * .69);
        canvas.drawPath(sad, facePaint);
        final tear = Paint()..color = const Color(0xFFBDEBFF);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * .64, h * .63),
            width: w * .035,
            height: h * .065,
          ),
          tear,
        );
        break;
      case MotiFace.anxious:
        canvas.drawCircle(Offset(w * .41, h * .56), w * .025, fillFace);
        canvas.drawCircle(Offset(w * .59, h * .56), w * .025, fillFace);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(w * .50, h * .68),
            width: w * .055,
            height: h * .065,
          ),
          facePaint,
        );
        break;
      case MotiFace.sleepy:
        canvas.drawLine(Offset(w * .37, h * .57), Offset(w * .45, h * .57), facePaint);
        canvas.drawLine(Offset(w * .55, h * .57), Offset(w * .63, h * .57), facePaint);
        final mouth = Path()
          ..moveTo(w * .47, h * .68)
          ..quadraticBezierTo(w * .50, h * .70, w * .53, h * .68);
        canvas.drawPath(mouth, facePaint);
        final zPaint = Paint()
          ..color = Colors.white.withValues(alpha: .92)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * .014
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;
        final z = Path()
          ..moveTo(w * .68, h * .43)
          ..lineTo(w * .76, h * .43)
          ..lineTo(w * .69, h * .51)
          ..lineTo(w * .77, h * .51);
        canvas.drawPath(z, zPaint);
        break;
    }

    final arm = Paint()
      ..color = Color.lerp(accent, const Color(0xFF4B3998), .25)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * .035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .26, h * .65), Offset(w * .18, h * .69), arm);
    canvas.drawLine(Offset(w * .74, h * .65), Offset(w * .82, h * .69), arm);
  }

  void _arcEye(
    Canvas canvas,
    Offset center,
    double radius,
    bool happy,
    Paint paint,
  ) {
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      happy ? pi * .08 : pi * 1.08,
      pi * .82,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _MotiPainter oldDelegate) {
    return oldDelegate.face != face || oldDelegate.accent != accent;
  }
}
