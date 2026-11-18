// Konfigurasi aplikasi dan pemeriksaan sesi.
part of 'package:nasabah_resik/main.dart';

// ---------------------------------------------------------------
// APP
// ---------------------------------------------------------------
class ResikApp extends StatelessWidget {
  const ResikApp({super.key});

  // google_fonts v9 punya tipe TextTheme sendiri, jadi font dipasang
  // per-style ke TextTheme bawaan Flutter.
  TextTheme _spaceGrotesk(TextTheme t) {
    TextStyle? f(TextStyle? s) =>
        s == null ? null : GoogleFonts.spaceGrotesk(textStyle: s);
    return t.copyWith(
      displayLarge: f(t.displayLarge),
      displayMedium: f(t.displayMedium),
      displaySmall: f(t.displaySmall),
      headlineLarge: f(t.headlineLarge),
      headlineMedium: f(t.headlineMedium),
      headlineSmall: f(t.headlineSmall),
      titleLarge: f(t.titleLarge),
      titleMedium: f(t.titleMedium),
      titleSmall: f(t.titleSmall),
      bodyLarge: f(t.bodyLarge),
      bodyMedium: f(t.bodyMedium),
      bodySmall: f(t.bodySmall),
      labelLarge: f(t.labelLarge),
      labelMedium: f(t.labelMedium),
      labelSmall: f(t.labelSmall),
    );
  }

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green),
      useMaterial3: true,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RESIK',
      theme: base.copyWith(textTheme: _spaceGrotesk(base.textTheme)),
      home: const SessionGate(),
    );
  }
}

class SessionGate extends StatefulWidget {
  const SessionGate({super.key});

  @override
  State<SessionGate> createState() => _SessionGateState();
}

class _SessionGateState extends State<SessionGate> {
  late final Future<bool> _session = _checkSession();

  Future<bool> _checkSession() async {
    if (!await ApiService.isLoggedIn()) return false;
    if (!await ApiService.shouldRememberMe()) {
      await ApiService.logout();
      return false;
    }
    try {
      await ApiService.getProfilSaya();
      return true;
    } on ApiException {
      await ApiService.logout();
      return false;
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<bool>(
    future: _session,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Tidak dapat memeriksa sesi ke server RESIK: ${snapshot.error}',
              ),
            ),
          ),
        );
      }
      return snapshot.data == true ? const MainShell() : const LoginScreen();
    },
  );
}

