import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'models.dart';
import 'screens.dart';

import 'dart:io'; // Добавьте этот импорт в самый верх файла, если его нет

void main() {
  // Насильно записываем идеальный XML файл манифеста прямо в систему
  try {
    final manifestFile = File('android/app/src/main/AndroidManifest.xml');
    manifestFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://android.com">
    <uses-permission android:name="android.permission.USE_BIOMETRIC"/>
    <application
        android:name="android.app.Application"
        android:label="Учет материалов"
        android:icon="@mipmap/ic_launcher">
        <meta-data android:name="flutterEmbedding" android:value="2" />
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <meta-data android:name="io.flutter.embedding.android.NormalTheme" android:resource="@style/NormalTheme"/>
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.action.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>''');
  } catch (e) {
    // Игнорируем ошибки, если файл заблокирован
  }

  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialCalculatorApp());
}

class MaterialCalculatorApp extends StatelessWidget {
  const MaterialCalculatorApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Учет материалов',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const MainCalculatorScreen(),
    );
  }
}

class MainCalculatorScreen extends StatefulWidget {
  const MainCalculatorScreen({super.key});
  @override
  State<MainCalculatorScreen> createState() => _MainCalculatorScreenState();
}

class _MainCalculatorScreenState extends State<MainCalculatorScreen> {
  final List<String> headers = [
    'Плитка 6-ка',
    'Плитка 8-ка',
    'Борд садовый',
    'Борт дорожный'
  ];
  final List<double> palletCapacities = [14.4, 12.2, 40.0, 16.0];

  MaterialProject currentProject = MaterialProject(
    id: 'current',
    name: 'Новый расчет',
    dateCreated: '',
    prices: [14.0, 18.0, 4.0, 9.0],
    quantities: [0.0, 0.0, 0.0, 0.0],
  );

  final LocalAuthentication auth = LocalAuthentication();

  double _calculateTotalSum() {
    double total = 0;
    for (int i = 0; i < 2; i++) {
      total += (currentProject.quantities[i] * palletCapacities[i]) *
          currentProject.prices[i];
    }
    for (int i = 2; i < 4; i++) {
      total += currentProject.quantities[i] * currentProject.prices[i];
    }
    return total;
  }

  Future<void> _tryAccessFinanceScreen() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isConfigured = prefs.getBool('auth_configured') ?? false;
    if (!mounted) return;

    if (!isConfigured) {
      Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => const SecuritySetupScreen()))
          .then((_) => setState(() {}));
      return;
    }

    final bool useBiometrics = prefs.getBool('use_biometrics') ?? false;
    final String savedPassword = prefs.getString('app_password') ?? "";

    if (useBiometrics) {
      try {
        bool authenticated = await auth.authenticate(
          localizedReason: 'Подтвердите личность для просмотра финансов',
          options: const AuthenticationOptions(
              biometricOnly: true, stickyAuth: true),
        );
        if (authenticated) {
          _openFinanceScreen();
          return;
        }
      } on PlatformException catch (e) {
        debugPrint(e.toString());
      }
    }
    _showPasswordDialog(savedPassword);
  }

  void _showPasswordDialog(String correctAnswer) {
    final TextEditingController passController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Доступ ограничен'),
        content: TextField(
            controller: passController,
            obscureText: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Введите пароль')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              if (passController.text.trim() == correctAnswer) {
                Navigator.pop(context);
                _openFinanceScreen();
              }
            },
            child: const Text('Войти'),
          ),
        ],
      ),
    );
  }

  void _openFinanceScreen() {
    currentProject.dateCreated =
        DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => FinanceScreen(
                totalSum: _calculateTotalSum(), project: currentProject)));
  }

  void _editPrice(int index) {
    TextEditingController controller =
        TextEditingController(text: currentProject.prices[index].toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Изменить цену: ${headers[index]}'),
        content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена')),
          TextButton(
            onPressed: () {
              setState(() {
                currentProject.prices[index] =
                    double.tryParse(controller.text) ??
                        currentProject.prices[index];
              });
              Navigator.pop(context);
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  void _editQuantity(int index) {
    TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Объем: ${headers[index]}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Количество')),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      currentProject.quantities[index] =
                          double.tryParse(controller.text) ?? 0.0;
                    });
                    Navigator.pop(context);
                  },
                  child: Text(index < 2 ? 'Поддоны' : 'Штуки'),
                ),
                ElevatedButton(
                  onPressed: () {
                    double val = double.tryParse(controller.text) ?? 0.0;
                    setState(() {
                      currentProject.quantities[index] =
                          val / palletCapacities[index];
                    });
                    Navigator.pop(context);
                  },
                  child: Text(index < 2 ? 'м²' : 'м.п.'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalSum = _calculateTotalSum();
    return Scaffold(
      appBar: AppBar(
          title: const Text('Калькулятор материалов'),
          backgroundColor: Colors.blue.shade100,
          actions: [
            IconButton(
                icon: const Icon(Icons.security),
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const SecuritySetupScreen())))
          ]),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: headers.length,
        itemBuilder: (context, index) {
          bool isTile = index < 2;
          double inputVal = currentProject.quantities[index];
          String volText = 'Не введено';
          double rowSum = 0;
          if (inputVal > 0) {
            if (isTile) {
              double sqMeters = inputVal * palletCapacities[index];
              volText =
                  '${inputVal.toStringAsFixed(1)} подд. (${sqMeters.toStringAsFixed(1)} м²)';
              rowSum = sqMeters * currentProject.prices[index];
            } else {
              double totalPcs = inputVal * palletCapacities[index];
              volText =
                  '${totalPcs.toStringAsFixed(0)} шт. (${inputVal.toStringAsFixed(1)} подд.)';
              rowSum = totalPcs * currentProject.prices[index];
            }
          }
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headers[index],
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Цена за ед:'),
                        TextButton(
                            onPressed: () => _editPrice(index),
                            child: Text('${currentProject.prices[index]} р'))
                      ]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Объем заказа:'),
                        TextButton(
                            onPressed: () => _editQuantity(index),
                            child: Text(inputVal > 0
                                ? '${inputVal.toStringAsFixed(1)} подд.'
                                : 'Ввести данные'))
                      ]),
                  const Divider(),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [const Text('Расчетный итог:'), Text(volText)]),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Сумма:',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${rowSum.toStringAsFixed(2)} руб.',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green))
                      ]),
                ],
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16.0),
        color: Colors.grey.shade100,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
                child: Text('Сумма: ${totalSum.toStringAsFixed(2)} руб.',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold))),
            ElevatedButton(
                onPressed: _tryAccessFinanceScreen,
                child: const Text('Финансы'))
          ],
        ),
      ),
    );
  }
}
