import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicialização de Notificações
  const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(android: initializationSettingsAndroid);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(const MambaFastTrackerApp());
}

class MambaFastTrackerApp extends StatelessWidget {
  const MambaFastTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mamba Fast Tracker',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: const Color(0xFF00E676),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676),
          secondary: Color(0xFF00B0FF),
          surface: Color(0xFF1E1E1E),
        ),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

// ==========================================
// 1. AUTENTICAÇÃO (RESPONSIVO)
// ==========================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLogged = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLogged = prefs.getBool('is_logged') ?? false;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    return _isLogged ? const MainNavigationScreen() : const LoginScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: "desafio@mamba.com");
  final _passwordController = TextEditingController(text: "123456");

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Preencha corretamente!"), backgroundColor: Colors.redAccent));
      return;
    }

    if (email == "desafio@mamba.com" && password == "123456") {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged', true);
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Credenciais inválidas!"), backgroundColor: Colors.redAccent));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.timer_outlined, size: 80, color: Color(0xFF00E676)),
                  const SizedBox(height: 16),
                  const Text("Mamba Fast Tracker", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 32),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: "E-mail", filled: true, fillColor: Color(0xFF1E1E1E))),
                  const SizedBox(height: 16),
                  TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: "Senha", filled: true, fillColor: Color(0xFF1E1E1E))),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black),
                      onPressed: _login,
                      child: const Text("ENTRAR NO APP", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. NAVEGAÇÃO PRINCIPAL
// ==========================================
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = const [FastTimerScreen(), MealsScreen(), MetricsScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E1E1E),
        indicatorColor: const Color(0xFF00E676).withOpacity(0.2),
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.timer_outlined), selectedIcon: Icon(Icons.timer, color: Color(0xFF00E676)), label: 'Jejum'),
          NavigationDestination(icon: Icon(Icons.restaurant_outlined), selectedIcon: Icon(Icons.restaurant, color: Color(0xFF00E676)), label: 'Refeições'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF00E676)), label: 'Métricas'),
        ],
      ),
    );
  }
}

// ==========================================
// 3. TIMER COM PAUSE, BACKGROUND E NOTIFICAÇÃO
// ==========================================
class FastTimerScreen extends StatefulWidget {
  const FastTimerScreen({super.key});
  @override
  State<FastTimerScreen> createState() => _FastTimerScreenState();
}

class _FastTimerScreenState extends State<FastTimerScreen> {
  Timer? _ticker;
  bool _isRunning = false, _isPaused = false;
  DateTime? _startTime;
  int _accumulatedSeconds = 0, _targetHours = 16, _currentElapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _loadTimerState();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'mamba_fast', 'Fasting Alerts', importance: Importance.max, priority: Priority.high,
    );
    await flutterLocalNotificationsPlugin.show(0, title, body, const NotificationDetails(android: androidDetails));
  }

  Future<void> _loadTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    _isRunning = prefs.getBool('is_running') ?? false;
    _isPaused = prefs.getBool('is_paused') ?? false;
    _targetHours = prefs.getInt('target_hours') ?? 16;
    _accumulatedSeconds = prefs.getInt('accumulated_seconds') ?? 0;
    
    final startStr = prefs.getString('start_time');
    if (startStr != null) _startTime = DateTime.parse(startStr);

    _updateDuration();
    if (_isRunning && !_isPaused) _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateDuration());
  }

  Future<void> _saveTimerState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_running', _isRunning);
    await prefs.setBool('is_paused', _isPaused);
    await prefs.setInt('target_hours', _targetHours);
    await prefs.setInt('accumulated_seconds', _accumulatedSeconds);
    if (_startTime != null) await prefs.setString('start_time', _startTime!.toIso8601String());
    else await prefs.remove('start_time');
  }

  void _updateDuration() {
    setState(() {
      if (_isRunning) {
        if (_isPaused) {
          _currentElapsedSeconds = _accumulatedSeconds;
        } else if (_startTime != null) {
          _currentElapsedSeconds = _accumulatedSeconds + DateTime.now().difference(_startTime!).inSeconds;
        }
      } else {
        _currentElapsedSeconds = 0;
      }
    });
  }

  Future<void> _startFast() async {
    setState(() {
      _isRunning = true; _isPaused = false; _startTime = DateTime.now();
      _accumulatedSeconds = 0; _currentElapsedSeconds = 0;
    });
    await _saveTimerState();
    _showNotification('Jejum Iniciado!', 'Seu protocolo de $_targetHours horas começou. Mantenha o foco!');
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateDuration());
  }

  Future<void> _pauseFast() async {
    _ticker?.cancel();
    setState(() {
      _isPaused = true;
      if (_startTime != null) _accumulatedSeconds += DateTime.now().difference(_startTime!).inSeconds;
      _startTime = null;
    });
    await _saveTimerState();
  }

  Future<void> _resumeFast() async {
    setState(() { _isPaused = false; _startTime = DateTime.now(); });
    await _saveTimerState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _updateDuration());
  }

  Future<void> _stopFast() async {
    _ticker?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final hoursCompleted = _currentElapsedSeconds / 3600.0;
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final history = prefs.getStringList('fast_history') ?? [];
    history.add(jsonEncode({'date': today, 'hours': hoursCompleted, 'target': _targetHours}));
    await prefs.setStringList('fast_history', history);
    
    // Atualiza cache de hoje para a tela de métricas
    await prefs.setDouble('fast_today_hours', hoursCompleted);

    setState(() { _isRunning = false; _isPaused = false; _startTime = null; _accumulatedSeconds = 0; _currentElapsedSeconds = 0; });
    await _saveTimerState();
    _showNotification('Jejum Finalizado!', 'Você concluiu ${hoursCompleted.toStringAsFixed(1)} horas. Bom trabalho!');
  }

  void _showCustomProtocolDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Protocolo Customizado (Horas)"),
        content: TextField(controller: controller, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () {
              final h = int.tryParse(controller.text);
              if (h != null && h > 0) setState(() => _targetHours = h);
              Navigator.pop(context);
            },
            child: const Text("Salvar"),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSecs) {
    final h = (totalSecs ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSecs % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSecs % 60).toString().padLeft(2, '0');
    return "$h:$m:$s";
  }

  @override
  Widget build(BuildContext context) {
    final targetSecs = _targetHours * 3600;
    final progress = (_isRunning && targetSecs > 0) ? (_currentElapsedSeconds / targetSecs).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text("Mamba Fast Tracker"), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Wrap(
                    spacing: 12, alignment: WrapAlignment.center,
                    children: [
                      _buildChip("12:12", 12),
                      _buildChip("16:8", 16),
                      _buildChip("18:6", 18),
                      ActionChip(label: const Text("Custom"), onPressed: _isRunning ? null : _showCustomProtocolDialog),
                    ],
                  ),
                  const SizedBox(height: 40),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 240, height: 240,
                        child: CircularProgressIndicator(
                          value: progress, strokeWidth: 14, backgroundColor: const Color(0xFF2A2A2A),
                          valueColor: AlwaysStoppedAnimation<Color>(_isPaused ? Colors.orange : const Color(0xFF00E676)),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_isRunning ? (_isPaused ? "PAUSADO" : "DECORRIDO") : "PRONTO", style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 8),
                          Text(_isRunning ? _formatDuration(_currentElapsedSeconds) : "${_targetHours.toString().padLeft(2, '0')}:00:00",
                              style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold)),
                          Text("Meta: ${_targetHours}h", style: const TextStyle(color: Color(0xFF00E676))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                  if (!_isRunning)
                    SizedBox(width: double.infinity, height: 56, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00E676), foregroundColor: Colors.black), onPressed: _startFast, child: const Text("INICIAR JEJUM")))
                  else
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _isPaused ? const Color(0xFF00E676) : Colors.orange, foregroundColor: Colors.black, padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: _isPaused ? _resumeFast : _pauseFast, child: Text(_isPaused ? "RETOMAR" : "PAUSAR"))),
                        const SizedBox(width: 16),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)), onPressed: _stopFast, child: const Text("ENCERRAR"))),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip(String label, int hours) => ChoiceChip(
    label: Text(label), selected: _targetHours == hours,
    selectedColor: const Color(0xFF00E676).withOpacity(0.2),
    onSelected: _isRunning ? null : (_) => setState(() => _targetHours = hours),
  );
}

// ==========================================
// 4. REFEIÇÕES COM FOTO (CAMERA LOCAL)
// ==========================================
class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});
  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  List<Map<String, dynamic>> _meals = [];

  @override
  void initState() { super.initState(); _loadMeals(); }

  Future<void> _loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('meals_today') ?? [];
    setState(() => _meals = raw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList());
  }

  Future<void> _saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('meals_today', _meals.map((e) => jsonEncode(e)).toList());
  }

  void _addOrEditMeal({int? index}) {
    final nameCtrl = TextEditingController(text: index != null ? _meals[index]['name'] : '');
    final calCtrl = TextEditingController(text: index != null ? _meals[index]['calories'].toString() : '');
    String? localPhotoPath = index != null ? _meals[index]['photo'] : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(index == null ? "Nova Refeição" : "Editar Refeição"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (localPhotoPath != null)
                  Padding(padding: const EdgeInsets.only(bottom: 12), child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(localPhotoPath!), height: 100, width: 100, fit: BoxFit.cover))),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt), label: const Text("Tirar Foto"),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.camera);
                    if (image != null) setDialogState(() => localPhotoPath = image.path);
                  },
                ),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Nome da Refeição")),
                TextField(controller: calCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Calorias")),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  final now = DateTime.now();
                  setState(() {
                    final mealData = {
                      'name': nameCtrl.text,
                      'calories': int.tryParse(calCtrl.text) ?? 0,
                      'time': index != null ? _meals[index]['time'] : "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
                      'photo': localPhotoPath,
                    };
                    if (index == null) _meals.add(mealData); else _meals[index] = mealData;
                  });
                  _saveMeals(); Navigator.pop(ctx);
                }
              },
              child: const Text("Salvar"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Refeições"), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (ctx, i) {
                final item = _meals[i];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), color: const Color(0xFF1E1E1E),
                  child: ListTile(
                    leading: item['photo'] != null 
                        ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(item['photo']), width: 50, height: 50, fit: BoxFit.cover))
                        : const Icon(Icons.fastfood, color: Color(0xFF00E676)),
                    title: Text(item['name']),
                    subtitle: Text("${item['time']} • ${item['calories']} kcal"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _addOrEditMeal(index: i)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () { setState(() => _meals.removeAt(i)); _saveMeals(); }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(onPressed: _addOrEditMeal, backgroundColor: const Color(0xFF00E676), child: const Icon(Icons.add, color: Colors.black)),
    );
  }
}

// ==========================================
// 5. MÉTRICAS SICRONIZADAS COM O DESAFIO
// ==========================================
class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});
  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  List<Map<String, dynamic>> _history = [];
  Map<int, double> _weekData = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0}; 
  int _todayCalories = 0;
  double _todayFastingHours = 0.0;
  final int _calorieGoal = 2000;
  int _fastingGoal = 16;

  @override
  void initState() { super.initState(); _loadMetrics(); }

  Future<void> _loadMetrics() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Dados de hoje (Sincronização)
    final rawMeals = prefs.getStringList('meals_today') ?? [];
    _todayCalories = rawMeals.map((e) => jsonDecode(e) as Map<String, dynamic>).fold<int>(0, (sum, item) => sum + (item['calories'] as int));
    _todayFastingHours = prefs.getDouble('fast_today_hours') ?? 0.0;
    _fastingGoal = prefs.getInt('target_hours') ?? 16;

    // Histórico e Gráfico
    final rawHistory = prefs.getStringList('fast_history') ?? [];
    List<Map<String, dynamic>> parsedHistory = [];
    Map<int, double> tempWeekData = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    final now = DateTime.now();

    for (var raw in rawHistory) {
      final item = jsonDecode(raw) as Map<String, dynamic>;
      parsedHistory.add(item);
      final itemDate = DateTime.parse(item['date']);
      if (now.difference(itemDate).inDays <= 7) tempWeekData[itemDate.weekday] = (tempWeekData[itemDate.weekday] ?? 0) + item['hours'];
    }

    setState(() { _history = parsedHistory.reversed.toList(); _weekData = tempWeekData; });
  }

  @override
  Widget build(BuildContext context) {
    final calStatus = _todayCalories <= _calorieGoal ? "DENTRO DA META" : "PASSOU DA META";
    final fastStatus = _todayFastingHours >= _fastingGoal ? "ALCANÇADA" : "EM ANDAMENTO";

    return Scaffold(
      appBar: AppBar(title: const Text("Resumo e Métricas"), backgroundColor: Colors.transparent),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sincronização do Dia (Requisito 6)
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard("Calorias Hoje", "$_todayCalories / $_calorieGoal", calStatus, _todayCalories <= _calorieGoal ? Colors.green : Colors.red)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard("Jejum Hoje", "${_todayFastingHours.toStringAsFixed(1)}h / ${_fastingGoal}h", fastStatus, _todayFastingHours >= _fastingGoal ? Colors.green : Colors.orange)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text("Evolução Semanal de Jejum", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Container(
                    height: 160, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround, crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _buildChartBar("Seg", _weekData[1]!), _buildChartBar("Ter", _weekData[2]!),
                        _buildChartBar("Qua", _weekData[3]!), _buildChartBar("Qui", _weekData[4]!),
                        _buildChartBar("Sex", _weekData[5]!), _buildChartBar("Sáb", _weekData[6]!), _buildChartBar("Dom", _weekData[7]!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text("Histórico de Conclusões", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ..._history.map((h) => ListTile(
                    leading: const Icon(Icons.check_circle, color: Color(0xFF00E676)),
                    title: Text("${h['hours'].toStringAsFixed(1)} horas"),
                    subtitle: Text("Data: ${h['date']}"),
                  )),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.5))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(status, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildChartBar(String day, double hours) {
    final pct = (hours / 24.0).clamp(0.05, 1.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("${hours.toStringAsFixed(1)}h", style: const TextStyle(fontSize: 10, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(width: 16, height: 90 * pct, decoration: BoxDecoration(color: const Color(0xFF00E676), borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 6),
        Text(day, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}