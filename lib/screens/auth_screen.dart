import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'pin_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  String _error = '';

  String _detectProvider(String key) {
    if (key.startsWith('sk-or-vv-')) return 'vsegpt';
    if (key.startsWith('sk-or-v1-')) return 'openrouter';
    return 'unknown';
  }

  Future<double?> _checkBalance(String key, String provider) async {
    try {
      final uri = provider == 'vsegpt'
          ? Uri.parse('https://api.vsegpt.ru/v1/balance')
          : Uri.parse('https://openrouter.ai/api/v1/auth/key');

      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $key'},
      ).timeout(const Duration(seconds: 10));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (provider == 'vsegpt') {
          return (data['balance'] as num?)?.toDouble();
        } else {
          return (data['data']['limit_remaining'] as num?)?.toDouble();
        }
      }
    } catch (e) {
      debugPrint('Balance check error: $e');
    }
    return null;
  }

  Future<void> _submit() async {
    final key = _controller.text.trim();
    if (key.isEmpty) return;

    final provider = _detectProvider(key);
    if (provider == 'unknown') {
      setState(() => _error =
          'Неверный формат ключа.\nОжидается sk-or-vv-... (VseGPT) или sk-or-v1-... (OpenRouter)');
      return;
    }

    setState(() {
      _loading = true;
      _error = '';
    });

    final balance = await _checkBalance(key, provider);
    setState(() => _loading = false);

    if (balance == null) {
      setState(() => _error = 'Ключ недействителен или ошибка сети');
      return;
    }
    if (balance <= 0) {
      final currency = provider == 'vsegpt' ? '₽' : '\$';
      setState(() => _error = 'Баланс нулевой: $balance $currency');
      return;
    }

    final pin = (1000 + Random().nextInt(9000)).toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', key);
    await prefs.setString('provider', provider);
    await prefs.setString('pin', pin);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PinScreen(
          generatedPin: pin,
          balance: balance,
          provider: provider,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Авторизация'),
        backgroundColor: const Color(0xFF262626),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            const Text(
              'Введите API ключ\nOpenRouter или VseGPT',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            const Text(
              'sk-or-v1-... → OpenRouter\nsk-or-vv-... → VseGPT',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _controller,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'API ключ',
                labelStyle: TextStyle(color: Colors.grey),
                hintText: 'sk-or-v1-... или sk-or-vv-...',
                hintStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Проверить и войти'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
