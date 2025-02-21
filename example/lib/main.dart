import 'package:flutter/material.dart';
import 'package:loggy/loggy.dart';
import 'package:vdb_secure_token/vdb_secure_token.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Loggy.initLoggy(
    logPrinter: const PrettyPrinter(showColors: true),
    logOptions: const LogOptions(
      LogLevel.debug,
      stackTraceLevel: LogLevel.error,
    ),
  );

  ConfigService.initVector = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4";
  ConfigService.key = "a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2";

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VDB Secure Token Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'VDB Secure Token Example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Text(
                'Secure payload obtained:',
              ),
              const SizedBox(height: 10),
              FutureBuilder(
                future: DeviceService.getSecurePayload(
                  platform: PlatformsEnum.fcm,
                  pushToken: "123qwe456",
                  locationMandatory: false,
                  locationTimeLimit: const Duration(seconds: 5),
                ),
                builder: (context, snapshot) => Text(
                  snapshot.data.toString(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
