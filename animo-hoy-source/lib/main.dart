import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AnimoHoyApp());
}

const motiRed = Color(0xFFF04432);
const motiRedDark = Color(0xFFC92F22);
const motiLeaf = Color(0xFF45A85D);
const appBackground = Color(0xFFFFF8F5);

enum MotiFace { happy, calm, neutral, sad, anxious, sleepy, angry, excited }

class Mood {
  const Mood({
    required this.label,
    required this.emoji,
    required this.face,
    required this.color,
    required this.soft,
    required this.sound,
    required this.messages,
    required this.actions,
  });

  final String label;
  final String emoji;
  final MotiFace face;
  final Color color;
  final Color soft;
  final String sound;
  final List<String> messages;
  final List<String> actions;
}

const moodItems = <Mood>[
  Mood(
    label: 'Feliz',
    emoji: '😄',
    face: MotiFace.happy,
    color: Color(0xFFFFA22E),
    soft: Color(0xFFFFE6B0),
    sound: 'feliz.wav',
    messages: [
      '¡Me encanta verte así! Guarda un poquito de esta alegría para más tarde.',
      'Qué bonito que hoy haya algo que te haga sentir bien. Disfrútalo.',
      'Tu alegría también puede convertirse en un recuerdo bonito.',
    ],
    actions: [
      'Anota una cosa que hizo bonito tu día.',
      'Comparte una palabra amable con alguien.',
      'Pon una canción que te guste y disfrútala un momento.',
    ],
  ),
  Mood(
    label: 'Tranquilo',
    emoji: '😌',
    face: MotiFace.calm,
    color: Color(0xFF37B8A5),
    soft: Color(0xFFC8EEE8),
    sound: 'tranquilo.wav',
    messages: [
      'Qué bien se siente un momento sin prisa. Me quedo aquí contigo.',
      'No necesitas llenar cada minuto. La calma también cuenta.',
      'Aprovechemos esta pausa para cuidar un poquito este momento.',
    ],
    actions: [
      'Haz tres respiraciones lentas.',
      'Toma un vaso de agua sin mirar el celular.',
      'Quédate un minuto en silencio y observa tu alrededor.',
    ],
  ),
  Mood(
    label: 'Normal',
    emoji: '🙂',
    face: MotiFace.neutral,
    color: Color(0xFF4C9BE8),
    soft: Color(0xFFD1E7FA),
    sound: 'normal.wav',
    messages: [
      'No todos los días tienen que ser intensos. Estar aquí también cuenta.',
      'Un día normal puede guardar algo bueno. Vamos paso a paso.',
      'Podemos hacer una cosa pequeña para darle un poquito de intención al día.',
    ],
    actions: [
      'Camina durante cinco minutos.',
      'Ordena un espacio pequeño.',
      'Haz una tarea sencilla que puedas terminar en menos de cinco minutos.',
    ],
  ),
  Mood(
    label: 'Triste',
    emoji: '😔',
    face: MotiFace.sad,
    color: Color(0xFF6F82C4),
    soft: Color(0xFFDCE2F7),
    sound: 'triste.wav',
    messages: [
      'Hoy parece pesado. No tienes que arreglarlo todo ahora; me quedo contigo un momento.',
      'Vamos despacio. Tu siguiente paso puede ser simplemente cuidarte un poquito.',
      'No voy a pedirte que sonrías. Solo hagamos juntos algo pequeño y amable contigo.',
    ],
    actions: [
      'Respira conmigo durante 30 segundos.',
      'Escribe una sola frase sobre lo que necesitas ahora.',
      'Haz algo amable por ti: agua, una ducha tranquila o un pequeño descanso.',
    ],
  ),
  Mood(
    label: 'Ansioso',
    emoji: '😟',
    face: MotiFace.anxious,
    color: Color(0xFF9267D5),
    soft: Color(0xFFE6D8F7),
    sound: 'ansioso.wav',
    messages: [
      'Una cosa a la vez. No necesitamos resolver mañana en este minuto.',
      'Mírame un segundo. Inhala lento y suelta el aire todavía más lento.',
      'Volvamos al presente: aquí, ahora, solo el siguiente paso.',
    ],
    actions: [
      'Haz la respiración guiada de 30 segundos.',
      'Nombra tres cosas que ves a tu alrededor.',
      'Deja el celular boca abajo durante cinco minutos.',
    ],
  ),
  Mood(
    label: 'Cansado',
    emoji: '😴',
    face: MotiFace.sleepy,
    color: Color(0xFF6F8793),
    soft: Color(0xFFD8E2E6),
    sound: 'cansado.wav',
    messages: [
      'Tu energía no es infinita. Descansar también forma parte del progreso.',
      'Hoy podemos bajar un poco el ritmo. No tienes que poder con todo.',
      'Hagamos espacio para recuperar energía sin sentir culpa.',
    ],
    actions: [
      'Cierra los ojos durante un minuto.',
      'Toma agua y estira hombros y cuello.',
      'Elige una tarea que realmente pueda esperar hasta mañana.',
    ],
  ),
  Mood(
    label: 'Enojado',
    emoji: '😡',
    face: MotiFace.angry,
    color: Color(0xFFE25B52),
    soft: Color(0xFFF7D6D2),
    sound: 'enojado.wav',
    messages: [
      'Puedo quedarme aquí mientras baja un poco la intensidad. No tienes que responder ahora mismo.',
      'Tu enojo trae información. Primero hagamos espacio para que el cuerpo se calme.',
      'Antes de reaccionar, vamos a recuperar unos segundos para ti.',
    ],
    actions: [
      'Aprieta y relaja las manos tres veces.',
      'Cuenta lentamente del cinco al uno.',
      'Aléjate un minuto de la situación si puedes hacerlo con seguridad.',
    ],
  ),
];

const dailyMissions = <String>[
  'Toma un vaso de agua con calma.',
  'Camina cinco minutos sin mirar el celular.',
  'Escribe una cosa por la que agradeces hoy.',
  'Ordena un espacio pequeño durante dos minutos.',
  'Respira con Moti durante 30 segundos.',
  'Envía un mensaje amable a alguien.',
  'Haz una pausa de un minuto y estira hombros y cuello.',
  'Escucha una canción que te haga bien.',
  'Mira por una ventana y observa tres detalles.',
  'Haz una tarea pequeña que hayas estado posponiendo.',
];

class MoodLog {
  const MoodLog({required this.date, required this.label, required this.emoji});

  final String date;
  final String label;
  final String emoji;

  Map<String, dynamic> toJson() => {'date': date, 'label': label, 'emoji': emoji};

  factory MoodLog.fromJson(Map<String, dynamic> json) => MoodLog(
        date: json['date'] as String? ?? '',
        label: json['label'] as String? ?? 'Normal',
        emoji: json['emoji'] as String? ?? '🙂',
      );
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
        scaffoldBackgroundColor: appBackground,
        colorScheme: ColorScheme.fromSeed(seedColor: motiRed),
        fontFamily: 'sans',
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _random = Random();
  final _player = AudioPlayer();

  bool _loading = true;
  int _tabIndex = 0;
  Mood? _selected;
  String _message = '¡Hola! Soy Moti. ¿Cómo estamos hoy?';
  String _action = 'Elige una emoción y te acompaño con un paso pequeño.';
  int _stars = 0;
  int _streak = 0;
  bool _missionDone = false;
  bool _soundOn = true;
  bool _hapticOn = true;
  String _lastLogDate = '';
  String _missionDate = '';
  String _breathingRewardDate = '';
  List<MoodLog> _logs = [];

  String get _today => _dateKey(DateTime.now());

  String get _todayMission {
    final now = DateTime.now();
    final index = (now.year + now.month * 31 + now.day) % dailyMissions.length;
    return dailyMissions[index];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawLogs = prefs.getString('logs');
    var loadedLogs = <MoodLog>[];
    if (rawLogs != null && rawLogs.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawLogs) as List<dynamic>;
        loadedLogs = decoded
            .whereType<Map<String, dynamic>>()
            .map(MoodLog.fromJson)
            .toList();
      } catch (_) {
        loadedLogs = [];
      }
    }

    var streak = prefs.getInt('streak') ?? 0;
    final lastDate = prefs.getString('lastLogDate') ?? '';
    if (lastDate.isNotEmpty && lastDate != _today && lastDate != _dateKey(DateTime.now().subtract(const Duration(days: 1)))) {
      streak = 0;
    }

    final missionDate = prefs.getString('missionDate') ?? '';
    final missionDone = missionDate == _today && (prefs.getBool('missionDone') ?? false);

    if (!mounted) return;
    setState(() {
      _stars = prefs.getInt('stars') ?? 0;
      _streak = streak;
      _lastLogDate = lastDate;
      _missionDate = missionDate;
      _missionDone = missionDone;
      _soundOn = prefs.getBool('soundOn') ?? true;
      _hapticOn = prefs.getBool('hapticOn') ?? true;
      _breathingRewardDate = prefs.getString('breathingRewardDate') ?? '';
      _logs = loadedLogs;
      _loading = false;
    });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('stars', _stars);
    await prefs.setInt('streak', _streak);
    await prefs.setString('lastLogDate', _lastLogDate);
    await prefs.setString('missionDate', _missionDate);
    await prefs.setBool('missionDone', _missionDone);
    await prefs.setBool('soundOn', _soundOn);
    await prefs.setBool('hapticOn', _hapticOn);
    await prefs.setString('breathingRewardDate', _breathingRewardDate);
    await prefs.setString('logs', jsonEncode(_logs.map((e) => e.toJson()).toList()));
  }

  Future<void> _playMoodSound(Mood mood) async {
    if (!_soundOn) return;
    try {
      await _player.stop();
      await _player.setVolume(.65);
      await _player.play(AssetSource('sounds/${mood.sound}'));
    } catch (_) {
      await SystemSound.play(SystemSoundType.click);
    }
  }

  Future<void> _chooseMood(Mood mood) async {
    if (_hapticOn) await HapticFeedback.lightImpact();
    await _playMoodSound(mood);

    final todayIndex = _logs.indexWhere((entry) => entry.date == _today);
    final firstLogToday = todayIndex < 0;
    var streak = _streak;
    var stars = _stars;

    if (firstLogToday) {
      final yesterday = _dateKey(DateTime.now().subtract(const Duration(days: 1)));
      streak = _lastLogDate == yesterday ? max(1, _streak + 1) : 1;
      stars += 5;
    }

    final log = MoodLog(date: _today, label: mood.label, emoji: mood.emoji);
    final nextLogs = [..._logs];
    if (todayIndex >= 0) {
      nextLogs[todayIndex] = log;
    } else {
      nextLogs.insert(0, log);
    }
    if (nextLogs.length > 90) nextLogs.removeRange(90, nextLogs.length);

    if (!mounted) return;
    setState(() {
      _selected = mood;
      _message = mood.messages[_random.nextInt(mood.messages.length)];
      _action = mood.actions[_random.nextInt(mood.actions.length)];
      _stars = stars;
      _streak = streak;
      _lastLogDate = _today;
      _logs = nextLogs;
    });
    await _persist();
  }

  void _newMessage() {
    final mood = _selected;
    if (mood == null) return;
    if (_hapticOn) HapticFeedback.selectionClick();
    setState(() {
      String next;
      do {
        next = mood.messages[_random.nextInt(mood.messages.length)];
      } while (next == _message && mood.messages.length > 1);
      _message = next;
      _action = mood.actions[_random.nextInt(mood.actions.length)];
    });
  }

  Future<void> _completeMission() async {
    if (_missionDone) return;
    if (_hapticOn) await HapticFeedback.mediumImpact();
    setState(() {
      _missionDone = true;
      _missionDate = _today;
      _stars += 10;
    });
    await _persist();
  }

  Future<void> _openBreathing() async {
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BreathingPage(soundOn: _soundOn, hapticOn: _hapticOn),
      ),
    );
    if (completed == true && _breathingRewardDate != _today) {
      setState(() {
        _stars += 5;
        _breathingRewardDate = _today;
      });
      await _persist();
    }
  }

  Future<void> _setSound(bool value) async {
    setState(() => _soundOn = value);
    await _persist();
  }

  Future<void> _setHaptic(bool value) async {
    setState(() => _hapticOn = value);
    await _persist();
  }

  Future<void> _resetProgress() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reiniciar progreso'),
        content: const Text('Se borrarán emociones guardadas, estrellas y racha de este dispositivo.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reiniciar')),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (!mounted) return;
    setState(() {
      _selected = null;
      _message = '¡Hola! Soy Moti. ¿Cómo estamos hoy?';
      _action = 'Elige una emoción y te acompaño con un paso pequeño.';
      _stars = 0;
      _streak = 0;
      _missionDone = false;
      _lastLogDate = '';
      _missionDate = '';
      _breathingRewardDate = '';
      _logs = [];
      _soundOn = true;
      _hapticOn = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pages = [
      _HomeTab(
        selected: _selected,
        message: _message,
        action: _action,
        stars: _stars,
        streak: _streak,
        mission: _todayMission,
        missionDone: _missionDone,
        onMood: _chooseMood,
        onNewMessage: _newMessage,
        onMissionDone: _completeMission,
        onBreathe: _openBreathing,
      ),
      _HistoryTab(logs: _logs, streak: _streak),
      _SettingsTab(
        soundOn: _soundOn,
        hapticOn: _hapticOn,
        onSound: _setSound,
        onHaptic: _setHaptic,
        onReset: _resetProgress,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tabIndex, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Inicio'),
          NavigationDestination(icon: Icon(Icons.calendar_month_rounded), label: 'Historial'),
          NavigationDestination(icon: Icon(Icons.tune_rounded), label: 'Ajustes'),
        ],
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  const _HomeTab({
    required this.selected,
    required this.message,
    required this.action,
    required this.stars,
    required this.streak,
    required this.mission,
    required this.missionDone,
    required this.onMood,
    required this.onNewMessage,
    required this.onMissionDone,
    required this.onBreathe,
  });

  final Mood? selected;
  final String message;
  final String action;
  final int stars;
  final int streak;
  final String mission;
  final bool missionDone;
  final Future<void> Function(Mood) onMood;
  final VoidCallback onNewMessage;
  final Future<void> Function() onMissionDone;
  final Future<void> Function() onBreathe;

  @override
  Widget build(BuildContext context) {
    final accent = selected?.color ?? motiRed;
    final face = selected?.face ?? MotiFace.excited;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hola 👋', style: TextStyle(color: Color(0xFF877772), fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Ánimo Hoy', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: -.8)),
                    ],
                  ),
                ),
                _StatPill(icon: '⭐', value: '$stars', color: Color(0xFFFFECC2)),
                const SizedBox(width: 8),
                _StatPill(icon: '🔥', value: '$streak', color: Color(0xFFFFDAD3)),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, Color.lerp(accent, Colors.white, .38)!],
                ),
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: accent.withValues(alpha: .2), blurRadius: 30, offset: const Offset(0, 14))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(color: Colors.white.withValues(alpha: .18), borderRadius: BorderRadius.circular(30)),
                        child: const Text('🥭  Moti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
                      ),
                      const Spacer(),
                      Text(selected?.label ?? 'Tu compañero', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Moti(key: ValueKey(face), face: face, size: 190),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .95), borderRadius: BorderRadius.circular(20)),
                    child: Column(
                      children: [
                        Text(message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15.5, height: 1.42, fontWeight: FontWeight.w800, color: Color(0xFF392D2A))),
                        if (selected != null)
                          TextButton.icon(
                            onPressed: onNewMessage,
                            icon: const Icon(Icons.auto_awesome_rounded, size: 17),
                            label: const Text('Otra frase'),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
            child: Text('¿Cómo te sientes?', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, letterSpacing: -.3)),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 101,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: moodItems.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final mood = moodItems[index];
                return _MoodButton(mood: mood, selected: mood == selected, onTap: () => onMood(mood));
              },
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
            child: _ActionCard(action: action, enabled: selected != null, onBreathe: onBreathe),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            child: _MissionCard(mission: mission, done: missionDone, onDone: onMissionDone),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.action, required this.enabled, required this.onBreathe});
  final String action;
  final bool enabled;
  final Future<void> Function() onBreathe;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF0E5E1))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [Text('✨', style: TextStyle(fontSize: 20)), SizedBox(width: 8), Text('Tu siguiente paso', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]),
          const SizedBox(height: 9),
          Text(action, style: TextStyle(fontSize: 15, height: 1.4, color: enabled ? const Color(0xFF554846) : const Color(0xFF9A8D89), fontWeight: FontWeight.w600)),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onBreathe,
              icon: const Icon(Icons.air_rounded),
              label: const Text('Respirar 30 segundos con Moti'),
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.done, required this.onDone});
  final String mission;
  final bool done;
  final Future<void> Function() onDone;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: done ? const Color(0xFFEAF7E9) : const Color(0xFFFFF0E9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: done ? const Color(0xFFB8DEB5) : const Color(0xFFFFD2C2)),
      ),
      child: Row(
        children: [
          Container(width: 48, height: 48, alignment: Alignment.center, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Text(done ? '✅' : '🎯', style: const TextStyle(fontSize: 23))),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(done ? 'Misión completada' : 'Misión de hoy · +10 ⭐', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                const SizedBox(height: 4),
                Text(mission, style: const TextStyle(height: 1.35, color: Color(0xFF62524D))),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(onPressed: done ? null : onDone, icon: Icon(done ? Icons.check_rounded : Icons.arrow_forward_rounded)),
        ],
      ),
    );
  }
}

class _MoodButton extends StatelessWidget {
  const _MoodButton({required this.mood, required this.selected, required this.onTap});
  final Mood mood;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? mood.soft : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: selected ? mood.color : const Color(0xFFF0E5E1), width: selected ? 2 : 1),
          boxShadow: selected ? [BoxShadow(color: mood.color.withValues(alpha: .18), blurRadius: 16, offset: const Offset(0, 7))] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 31)),
            const SizedBox(height: 5),
            Text(mood.label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: selected ? mood.color : const Color(0xFF675A56))),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.value, required this.color});
  final String icon;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(18)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(icon), const SizedBox(width: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w900))]),
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.logs, required this.streak});
  final List<MoodLog> logs;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final cutoff = DateTime.now().subtract(const Duration(days: 6));
    final counts = <String, int>{};
    for (final log in logs) {
      final date = DateTime.tryParse(log.date);
      if (date != null && !date.isBefore(DateTime(cutoff.year, cutoff.month, cutoff.day))) {
        counts[log.emoji] = (counts[log.emoji] ?? 0) + 1;
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text('Tu historial', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: -.8)),
        const SizedBox(height: 4),
        const Text('Mira cómo te has sentido y reconoce tus propios patrones.', style: TextStyle(color: Color(0xFF867773), height: 1.4)),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF0E5E1))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [const Text('🔥', style: TextStyle(fontSize: 25)), const SizedBox(width: 9), Text('$streak días de racha', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900))]),
              const SizedBox(height: 13),
              const Text('Últimos 7 días', style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF766762))),
              const SizedBox(height: 8),
              if (counts.isEmpty)
                const Text('Registra tu primera emoción para comenzar.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: counts.entries.map((entry) => Chip(label: Text('${entry.key}  ${entry.value}'))).toList(),
                ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text('Registros recientes', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        const SizedBox(height: 9),
        if (logs.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: const Color(0xFFFFEEE8), borderRadius: BorderRadius.circular(24)),
            child: const Column(children: [Moti(face: MotiFace.calm, size: 120), SizedBox(height: 8), Text('Todavía no hay registros. Tu primer día empieza cuando eliges una emoción.', textAlign: TextAlign.center)]),
          )
        else
          ...logs.take(30).map(
                (log) => Container(
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFF1E6E2))),
                  child: Row(children: [Text(log.emoji, style: const TextStyle(fontSize: 27)), const SizedBox(width: 12), Expanded(child: Text(log.label, style: const TextStyle(fontWeight: FontWeight.w900))), Text(_prettyDate(log.date), style: const TextStyle(color: Color(0xFF8D7F7A), fontSize: 12))]),
                ),
              ),
      ],
    );
  }
}

class _SettingsTab extends StatelessWidget {
  const _SettingsTab({required this.soundOn, required this.hapticOn, required this.onSound, required this.onHaptic, required this.onReset});
  final bool soundOn;
  final bool hapticOn;
  final Future<void> Function(bool) onSound;
  final Future<void> Function(bool) onHaptic;
  final Future<void> Function() onReset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      children: [
        const Text('Ajustes', style: TextStyle(fontSize: 29, fontWeight: FontWeight.w900, letterSpacing: -.8)),
        const SizedBox(height: 4),
        const Text('Haz que Moti se sienta cómodo para ti.', style: TextStyle(color: Color(0xFF867773))),
        const SizedBox(height: 20),
        _SettingTile(icon: Icons.volume_up_rounded, title: 'Sonidos de emociones', subtitle: 'Cada emoción tiene un sonido corto diferente.', trailing: Switch(value: soundOn, onChanged: onSound)),
        _SettingTile(icon: Icons.vibration_rounded, title: 'Vibración suave', subtitle: 'Pequeñas respuestas al tocar y completar acciones.', trailing: Switch(value: hapticOn, onChanged: onHaptic)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: const Color(0xFFFFEEE7), borderRadius: BorderRadius.circular(24)),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [Text('🥭', style: TextStyle(fontSize: 25)), SizedBox(width: 9), Text('Moti en tu pantalla principal', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900))]),
              SizedBox(height: 8),
              Text('Esta versión incluye un widget de Android. Mantén pulsada una zona vacía de tu pantalla principal, entra en Widgets y busca “Ánimo Hoy”.', style: TextStyle(height: 1.45, color: Color(0xFF695A55))),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFF0E5E1))),
          child: const Text('Tus emociones, racha y estrellas se guardan solamente en este dispositivo en esta versión de prueba. Ánimo Hoy no sustituye atención profesional de salud.', style: TextStyle(height: 1.45, color: Color(0xFF746762))),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(onPressed: onReset, icon: const Icon(Icons.restart_alt_rounded), label: const Text('Reiniciar progreso de prueba')),
      ],
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({required this.icon, required this.title, required this.subtitle, required this.trailing});
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFF0E5E1))),
      child: Row(
        children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFFFE5DD), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: motiRedDark)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(subtitle, style: const TextStyle(fontSize: 12, height: 1.3, color: Color(0xFF8A7A75)))])),
          trailing,
        ],
      ),
    );
  }
}

class BreathingPage extends StatefulWidget {
  const BreathingPage({super.key, required this.soundOn, required this.hapticOn});
  final bool soundOn;
  final bool hapticOn;

  @override
  State<BreathingPage> createState() => _BreathingPageState();
}

class _BreathingPageState extends State<BreathingPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  final _player = AudioPlayer();
  Timer? _timer;
  int _elapsed = 0;
  bool _done = false;

  String get _phase {
    final second = _elapsed % 12;
    if (second < 4) return 'Inhala';
    if (second < 6) return 'Sostén';
    return 'Exhala';
  }

  int get _remaining => max(0, 30 - _elapsed);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat();
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: .78, end: 1.13).chain(CurveTween(curve: Curves.easeInOut)), weight: 4),
      TweenSequenceItem(tween: ConstantTween(1.13), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.13, end: .78).chain(CurveTween(curve: Curves.easeInOut)), weight: 6),
    ]).animate(_controller);
    _startAudio();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _elapsed++);
      if (_elapsed >= 30) {
        timer.cancel();
        _controller.stop();
        _player.stop();
        if (widget.hapticOn) HapticFeedback.mediumImpact();
        setState(() => _done = true);
      }
    });
  }

  Future<void> _startAudio() async {
    if (!widget.soundOn) return;
    try {
      await _player.setVolume(.28);
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.play(AssetSource('sounds/respirar.wav'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respirar con Moti')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              if (!_done) ...[
                Text(_phase, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                Text('$_remaining s', style: const TextStyle(fontSize: 18, color: Color(0xFF877772), fontWeight: FontWeight.w700)),
                const SizedBox(height: 35),
                AnimatedBuilder(
                  animation: _scale,
                  builder: (context, child) => Transform.scale(scale: _scale.value, child: child),
                  child: Container(
                    width: 230,
                    height: 230,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFFFFDED4), boxShadow: [BoxShadow(color: motiRed.withValues(alpha: .18), blurRadius: 38, spreadRadius: 6)]),
                    alignment: Alignment.center,
                    child: const Moti(face: MotiFace.calm, size: 170),
                  ),
                ),
                const SizedBox(height: 35),
                const Text('Sigue el movimiento de Moti. No necesitas hacerlo perfecto.', textAlign: TextAlign.center, style: TextStyle(height: 1.45, color: Color(0xFF756762))),
              ] else ...[
                const Moti(face: MotiFace.happy, size: 210),
                const SizedBox(height: 18),
                const Text('¡Listo! 🌿', style: TextStyle(fontSize: 31, fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                const Text('Treinta segundos para volver un poquito al presente.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, height: 1.45, color: Color(0xFF756762))),
              ],
              const Spacer(),
              SizedBox(width: double.infinity, child: FilledButton(onPressed: _done ? () => Navigator.pop(context, true) : null, child: const Text('Volver a Ánimo Hoy'))),
            ],
          ),
        ),
      ),
    );
  }
}

class Moti extends StatelessWidget {
  const Moti({super.key, required this.face, this.size = 180});
  final MotiFace face;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CustomPaint(painter: _MotiPainter(face)));
  }
}

class _MotiPainter extends CustomPainter {
  _MotiPainter(this.face);
  final MotiFace face;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final body = Paint()..color = motiRed;
    final bodyDark = Paint()..color = motiRedDark;
    final facePaint = Paint()..color = const Color(0xFF3D2722)..strokeWidth = w * .045..strokeCap = StrokeCap.round..style = PaintingStyle.stroke;
    final blush = Paint()..color = const Color(0xFFFF9C8C).withValues(alpha: .85);

    canvas.save();
    canvas.translate(w * .56, h * .17);
    canvas.rotate(-.45);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: w * .34, height: h * .18), Paint()..color = motiLeaf);
    canvas.restore();
    canvas.drawLine(Offset(w * .51, h * .25), Offset(w * .56, h * .13), Paint()..color = const Color(0xFF31854A)..strokeWidth = w * .035..strokeCap = StrokeCap.round);

    final bodyRect = RRect.fromRectAndRadius(Rect.fromLTWH(w * .16, h * .22, w * .68, h * .68), Radius.circular(w * .29));
    canvas.drawRRect(bodyRect, bodyDark);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * .16, h * .20, w * .68, h * .66), Radius.circular(w * .29)), body);
    canvas.drawOval(Rect.fromLTWH(w * .27, h * .28, w * .22, h * .10), Paint()..color = Colors.white.withValues(alpha: .13));

    canvas.drawCircle(Offset(w * .29, h * .62), w * .055, blush);
    canvas.drawCircle(Offset(w * .71, h * .62), w * .055, blush);

    final leftEye = Offset(w * .38, h * .51);
    final rightEye = Offset(w * .62, h * .51);
    final eyeFill = Paint()..color = const Color(0xFF3D2722);

    if (face == MotiFace.sleepy || face == MotiFace.calm) {
      canvas.drawLine(Offset(leftEye.dx - w * .045, leftEye.dy), Offset(leftEye.dx + w * .045, leftEye.dy + (face == MotiFace.calm ? w * .01 : 0)), facePaint);
      canvas.drawLine(Offset(rightEye.dx - w * .045, rightEye.dy), Offset(rightEye.dx + w * .045, rightEye.dy + (face == MotiFace.calm ? w * .01 : 0)), facePaint);
    } else {
      canvas.drawCircle(leftEye, w * .035, eyeFill);
      canvas.drawCircle(rightEye, w * .035, eyeFill);
    }

    if (face == MotiFace.angry) {
      canvas.drawLine(Offset(w * .32, h * .43), Offset(w * .42, h * .46), facePaint);
      canvas.drawLine(Offset(w * .58, h * .46), Offset(w * .68, h * .43), facePaint);
    } else if (face == MotiFace.sad) {
      canvas.drawLine(Offset(w * .33, h * .45), Offset(w * .42, h * .43), facePaint);
      canvas.drawLine(Offset(w * .58, h * .43), Offset(w * .67, h * .45), facePaint);
    } else if (face == MotiFace.anxious) {
      canvas.drawLine(Offset(w * .33, h * .44), Offset(w * .42, h * .46), facePaint);
      canvas.drawLine(Offset(w * .58, h * .46), Offset(w * .67, h * .44), facePaint);
    }

    final mouthRect = Rect.fromCenter(center: Offset(w * .50, h * .63), width: w * .25, height: h * .17);
    switch (face) {
      case MotiFace.happy:
      case MotiFace.excited:
        canvas.drawArc(mouthRect, .15, pi - .3, false, facePaint);
        break;
      case MotiFace.calm:
        canvas.drawArc(mouthRect, .35, pi - .7, false, facePaint);
        break;
      case MotiFace.sad:
        canvas.drawArc(mouthRect, pi + .15, pi - .3, false, facePaint);
        break;
      case MotiFace.anxious:
        canvas.drawOval(Rect.fromCenter(center: Offset(w * .5, h * .64), width: w * .08, height: h * .10), facePaint);
        break;
      case MotiFace.sleepy:
        canvas.drawLine(Offset(w * .46, h * .64), Offset(w * .55, h * .64), facePaint);
        break;
      case MotiFace.angry:
        canvas.drawArc(mouthRect, pi + .25, pi - .5, false, facePaint);
        break;
      case MotiFace.neutral:
        canvas.drawLine(Offset(w * .45, h * .64), Offset(w * .55, h * .64), facePaint);
        break;
    }

    final armPaint = Paint()..color = motiRedDark..strokeWidth = w * .045..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * .18, h * .62), Offset(w * .08, h * .69), armPaint);
    canvas.drawLine(Offset(w * .82, h * .62), Offset(w * .92, h * .69), armPaint);
  }

  @override
  bool shouldRepaint(covariant _MotiPainter oldDelegate) => oldDelegate.face != face;
}

String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String _prettyDate(String raw) {
  final date = DateTime.tryParse(raw);
  if (date == null) return raw;
  const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  return '${date.day} ${months[date.month - 1]}';
}
