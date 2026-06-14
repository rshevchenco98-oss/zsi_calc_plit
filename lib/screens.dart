import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class FinanceScreen extends StatelessWidget {
  final double totalSum;
  final MaterialProject project;

  const FinanceScreen({super.key, required this.totalSum, required this.project});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Финансовый отчет'), backgroundColor: Colors.green.shade100),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ПЕРЕНЕСЕННАЯ СУММА:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text('${totalSum.toStringAsFixed(2)} руб.', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),
            _buildRow('Строка 1 (30% от общей суммы):', totalSum * 0.30),
            _buildRow('Строка 2 (5% от общей суммы):', totalSum * 0.05),
            _buildRow('Строка 3 (5% от общей суммы):', totalSum * 0.05),
            const Divider(height: 40, thickness: 2),
            Card(
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ИТОГОВЫЙ ЗАРАБОТОК:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('${(totalSum * 0.60).toStringAsFixed(2)} руб.', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
       child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 14)),
          Text('${value.toStringAsFixed(2)} руб.', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class SecuritySetupScreen extends StatefulWidget {
  const SecuritySetupScreen({super.key});
  @override
  State<SecuritySetupScreen> createState() => _SecuritySetupScreenState();
}

class _SecuritySetupScreenState extends State<SecuritySetupScreen> {
  final TextEditingController _passController = TextEditingController();
  bool _useBiometrics = true;

  Future<void> _saveSettings() async {
    if (_passController.text.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_password', _passController.text.trim());
    await prefs.setBool('use_biometrics', _useBiometrics);
    await prefs.setBool('auth_configured', true);
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройка безопасности')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _passController,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Задайте цифровой пароль для входа'),
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Использовать биометрию (отпечаток/лицо)'),
              value: _useBiometrics,
              onChanged: (val) => setState(() => _useBiometrics = val),
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: _saveSettings, child: const Text('Сохранить настройки защиты'))
          ],
        ),
      ),
    );
  }
}
