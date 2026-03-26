import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_screen.dart';
import 'chat_screen.dart';

class PinScreen extends StatefulWidget {
  final String? generatedPin;
  final double? balance;
  final String? provider;

  const PinScreen({super.key, this.generatedPin, this.balance, this.provider});

  @override
  State<PinScreen> createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final _controller = TextEditingController();
  String _error = '';

  bool get _isFirstTime => widget.generatedPin != null;

  Future<void> _submit() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPin = prefs.getString('pin') ?? '';

    if (_controller.text.trim() == savedPin) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } else {
      setState(() => _error = 'Неверный PIN. Попробуйте ещё раз.');
      _controller.clear();
    }
  }

  Future<void> _resetKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF333333),
        title:
            const Text('Сбросить ключ?', style: TextStyle(color: Colors.white)),
        content: const Text(
            'PIN и API ключ будут удалены. Придётся войти заново.',
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Сбросить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('api_key');
    await prefs.remove('pin');
    await prefs.remove('provider');

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.provider == 'vsegpt' ? '₽' : '\$';
    final providerName = widget.provider == 'vsegpt' ? 'VseGPT' : 'OpenRouter';

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        title: const Text('Введите PIN'),
        backgroundColor: const Color(0xFF262626),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isFirstTime) ...[
              const Icon(Icons.check_circle, color: Colors.green, size: 72),
              const SizedBox(height: 16),
              Text(
                'Провайдер: $providerName',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'Баланс: ${widget.balance?.toStringAsFixed(2)} $currency',
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('Ваш PIN:',
                  style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue),
                ),
                child: Text(
                  widget.generatedPin ?? '',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    letterSpacing: 16,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Запомните PIN — он нужен при следующем входе',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
            ] else
              const Column(
                children: [
                  Icon(Icons.pin, size: 64, color: Colors.blue),
                  SizedBox(height: 16),
                  Text(
                    'Введите PIN для входа',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
                  SizedBox(height: 24),
                ],
              ),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white, fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                labelText: '4-значный PIN',
                labelStyle: TextStyle(color: Colors.grey),
                counterStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                ),
              ),
            ),
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Войти'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _resetKey,
              child: const Text(
                'Сбросить ключ и ввести новый',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
