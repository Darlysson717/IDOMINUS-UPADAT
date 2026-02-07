import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'publicar_anuncio_page.dart';
import 'comprador_home.dart';
import 'login_page.dart';
import 'onboarding_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'detalhes_veiculo_page.dart';
import 'favoritos_page.dart';
import 'meus_anuncios_page.dart';
import 'visualizacoes_page.dart';
import 'top_favoritos_page.dart';
import 'perfil_page.dart';
import 'seller_verification_page.dart';
import 'notifications_page.dart';
import 'lojistas_seguidos_page.dart';
import 'lojista_anuncios_page.dart';
import 'sobre_dominus_page.dart';
import 'ads_statistics_page.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:package_info_plus/package_info_plus.dart';
import 'services/notification_service.dart';
import 'services/presence_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Supabase primeiro
  await Supabase.initialize(
    url: 'https://xwusadbehasobjzkqsgk.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh3dXNhZGJlaGFzb2Jqemtxc2drIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1OTAzMzgsImV4cCI6MjA3MjE2NjMzOH0.oupGPTAuMGkpdZkWZFd2wA5c5Jx22yMcdBAJaoJqJoE',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
      autoRefreshToken: true,
    ),
    debug: false, // Desabilitar debug para produção
  );

  // Inicializar PresenceService para contar usuários online
  await PresenceService().start();

  // Inicializar notificações (removido WorkManager problemático)
  try {
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Erro ao inicializar notificações: $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: DeepLinkHandler(child: const MyApp()),
    ),
  );
}

class DeepLinkHandler extends StatefulWidget {
  final Widget child;
  const DeepLinkHandler({super.key, required this.child});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<DeepLinkHandler> createState() => _DeepLinkHandlerState();
}

class _DeepLinkHandlerState extends State<DeepLinkHandler> {
  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  void _initDeepLinks() async {
    // Handle initial link
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleDeepLink(initialUri);
      });
    }

    // Handle incoming links
    _linkSubscription = _appLinks.uriLinkStream.listen((Uri uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    if (uri.scheme == 'dominus') {
      if (uri.host == 'seller') {
        final sellerId = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
        if (sellerId != null && sellerId.isNotEmpty) {
          _openSellerFromLink(sellerId);
        }
      }
      return;
    }

    if (uri.host != 'domin.us') return;

    if (uri.path.startsWith('/vehicle/')) {
      final vehicleId = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : null;
      if (vehicleId != null && vehicleId.isNotEmpty) {
        DeepLinkHandler.navigatorKey.currentState?.pushNamed('/vehicle', arguments: {'id': vehicleId});
      }
      return;
    }

    if (uri.path.startsWith('/seller/')) {
      final sellerId = uri.pathSegments.length >= 2 ? uri.pathSegments.last : null;
      if (sellerId != null && sellerId.isNotEmpty) {
        _openSellerFromLink(sellerId);
      }
      return;
    }

    if (uri.path == '/seller_redirect.html') {
      final sellerId = uri.queryParameters['seller'];
      if (sellerId != null && sellerId.isNotEmpty) {
        _openSellerFromLink(sellerId);
      }
    }
  }

  void _openSellerFromLink(String sellerId) {
    DeepLinkHandler.navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => LojistaAnunciosPage(sellerId: sellerId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late final StreamSubscription<AuthState> _authSubscription;
  bool _isLoading = true;
  User? _user;
  bool _showOnboarding = false;
  StreamSubscription? _notificationSubscription;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
    // _checkForUpdateAtStartup() removido temporariamente
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      debugPrint('AuthWrapper event: ${data.event}, session: ${data.session != null}');
      setState(() {
        _user = data.session?.user;
        _isLoading = false;
      });
      if (_user != null) {
        _startNotificationListener();
      } else {
        _stopNotificationListener();
      }
    });
    final current = Supabase.instance.client.auth.currentUser;
    if (current != null) {
      debugPrint('AuthWrapper restore session for user ${current.id}');
      setState(() {
        _user = current;
        _isLoading = false;
      });
      _startNotificationListener();
    }
  }

  Future<void> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    final packageInfo = await PackageInfo.fromPlatform();
    final currentVersion = packageInfo.version;
    final savedVersion = prefs.getString('app_version');

    // Mostrar onboarding se é primeira vez ou versão mudou
    if (savedVersion == null || savedVersion != currentVersion) {
      setState(() {
        _showOnboarding = true;
      });
      // Salvar versão atual
      await prefs.setString('app_version', currentVersion);
    } else {
      setState(() {
        _showOnboarding = false;
      });
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    setState(() {
      _showOnboarding = false;
    });
  }

  void _startNotificationListener() {
    _notificationSubscription?.cancel();
    if (_user == null) return;
    _notificationSubscription = Supabase.instance.client
        .from('notificacoes')
        .stream(primaryKey: ['id'])
        .eq('user_id', _user!.id)
        .listen((data) {
          for (var notification in data) {
            if (!notification['lida']) {
              NotificationService.showNotification(
                title: 'Nova notificação',
                body: notification['mensagem'],
              );
            }
          }
        }, onError: (error) {
          debugPrint('❌ NOTIFICATION: Listener error: $error');
        });
  }

  void _stopNotificationListener() {
    _notificationSubscription?.cancel();
    _notificationSubscription = null;
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _stopNotificationListener();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      debugPrint('⏳ AuthWrapper: Carregando...');
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_showOnboarding) {
      debugPrint('📖 AuthWrapper: Mostrando onboarding');
      return OnboardingPage(onFinish: _finishOnboarding);
    }
    
    // Para web, mostrar tela principal diretamente para teste
    if (kIsWeb) {
      debugPrint('🌐 Modo web: pulando login, mostrando CompradorHome');
      return CompradorHome();
    }
    
    if (_user == null) {
      debugPrint('🔐 AuthWrapper: Usuário não logado, mostrando LoginPage');
      return LoginPage();
    } else {
      debugPrint('✅ AuthWrapper: Usuário logado (${_user!.id}), mostrando CompradorHome');
      return CompradorHome();
    }
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Dominus',
          navigatorKey: DeepLinkHandler.navigatorKey,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeProvider.themeMode,
          home: const AuthWrapper(),
          routes: {
            '/publicar': (context) => PublicarAnuncioPage(anuncio: ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?),
            '/home': (context) => CompradorHome(),
            '/login': (context) => LoginPage(),
            '/detalhes': (context) => const DetalhesVeiculoPage(),
            '/vehicle': (context) => const DetalhesVeiculoPage(), // Para deep links
            '/favoritos': (context) => const FavoritosPage(),
            '/meus-anuncios': (context) => const MeusAnunciosPage(),
            '/visualizacoes': (context) => const VisualizacoesPage(),
            '/mais-favoritos': (context) => const TopFavoritosPage(),
            '/perfil': (context) => const PerfilPage(),
            '/seller-verification': (context) => const SellerVerificationPage(),
            '/notifications': (context) => const NotificationsPage(),
            '/lojistas': (context) => const LojistasSeguidosPage(),
            '/sobre-dominus': (context) => const SobreDominusPage(),
            '/ads-statistics': (context) => const AdsStatisticsPage(),
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF1A237E), // Azul escuro premium
        secondary: Color(0xFF3949AB), // Azul médio
        tertiary: Color(0xFF5E35B1), // Roxo elegante
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1C1B1F),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A237E),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A237E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textTheme: GoogleFonts.montserratTextTheme().copyWith(
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1A237E),
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A237E),
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1C1B1F),
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          color: const Color(0xFF1C1B1F),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: GoogleFonts.montserrat().fontFamily,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3949AB), // Azul médio para dark
        secondary: Color(0xFF5E35B1), // Roxo elegante
        tertiary: Color(0xFF7986CB), // Azul claro
        surface: Color(0xFF1C1B1F),
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1B1F),
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: const Color(0xFF1C1B1F),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3949AB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme).copyWith(
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          color: Colors.white,
        ),
      ),
    );
  }
}



// ...existing code...

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
// ...existing code...

