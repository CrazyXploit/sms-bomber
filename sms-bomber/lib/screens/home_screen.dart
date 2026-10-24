import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/api_endpoint.dart';
import '../services/bomber_service.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/animated_counter.dart';
import '../widgets/status_dot.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _phoneCtrl = TextEditingController();
  final _countCtrl = TextEditingController(text: '50');
  final _concCtrl = TextEditingController(text: '5');
  final _bomber = BomberService();

  List<ApiEndpoint> _apis = [];
  int _sent = 0;
  int _failed = 0;
  bool _isRunning = false;
  bool _done = false;

  static const _prefKey = 'api_endpoints_pro_v1';

  @override
  void initState() {
    super.initState();
    _loadApis();
  }

  Future<void> _loadApis() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw != null) {
      final list = (jsonDecode(raw) as List)
          .map((e) => ApiEndpoint.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      setState(() => _apis = list);
    } else {
      setState(() => _apis = [
            ApiEndpoint(
              name: 'Demo API',
              url: 'https://httpbin.org/post',
              method: 'POST',
              bodyTemplate: '{"phone":"{phone}","msg":"code"}',
            ),
          ]);
      _saveApis();
    }
  }

  Future<void> _saveApis() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefKey, jsonEncode(_apis.map((e) => e.toJson()).toList()));
  }

  Future<void> _start() async {
    final phone = _phoneCtrl.text.trim();
    final total = int.tryParse(_countCtrl.text) ?? 0;
    final conc = int.tryParse(_concCtrl.text) ?? 1;
    if (phone.isEmpty || total <= 0 || conc <= 0) return;

    setState(() {
      _isRunning = true;
      _done = false;
      _sent = 0;
      _failed = 0;
    });

    await _bomber.start(
      endpoints: _apis,
      targetNumber: phone,
      totalSms: total,
      concurrency: conc,
      onProgress: (s, f) => setState(() {
        _sent = s;
        _failed = f;
      }),
      onComplete: () => setState(() {
        _isRunning = false;
        _done = true;
      }),
    );
  }

  void _stop() {
    _bomber.stop();
    setState(() => _isRunning = false);
  }

  void _addApiDialog({ApiEndpoint? existing, int? index}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final urlCtrl = TextEditingController(text: existing?.url ?? '');
    final bodyCtrl =
        TextEditingController(text: existing?.bodyTemplate ?? '{"phone":"{phone}"}');
    String method = existing?.method ?? 'POST';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 24, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(existing == null ? 'New endpoint' : 'Edit endpoint',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlCtrl,
                decoration: const InputDecoration(
                    labelText: 'URL ({phone} placeholder supported)'),
              ),
              const SizedBox(height: 12),
              Row(
                children: ['POST', 'GET'].map((m) {
                  final sel = method == m;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setLocal(() => method = m),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: sel
                              ? AppColors.accent.withOpacity(0.15)
                              : AppColors.surfaceHi,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: sel ? AppColors.accent : AppColors.border,
                          ),
                        ),
                        child: Text(
                          m,
                          style: TextStyle(
                            color: sel ? AppColors.accent : AppColors.textDim,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Body template ({phone} = target)'),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.bg,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (nameCtrl.text.isEmpty || urlCtrl.text.isEmpty) {
                          return;
                        }
                        final api = ApiEndpoint(
                          name: nameCtrl.text,
                          url: urlCtrl.text,
                          method: method,
                          bodyTemplate: bodyCtrl.text,
                          enabled: existing?.enabled ?? true,
                        );
                        setState(() {
                          if (index == null) {
                            _apis.add(api);
                          } else {
                            _apis[index] = api;
                          }
                        });
                        _saveApis();
                        Navigator.pop(ctx);
                      },
                      child: Text(existing == null ? 'Add endpoint' : 'Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final enabledCount = _apis.where((e) => e.enabled).length;
    final total = int.tryParse(_countCtrl.text) ?? 1;
    final progress = total == 0
        ? 0.0
        : ((_sent + _failed) / total).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.bg, AppColors.bgAlt, Color(0xFF0E1320)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildHeroPanel(progress, enabledCount),
                const SizedBox(height: 24),
                _buildInputCard(),
                const SizedBox(height: 20),
                _buildApiSection(enabledCount),
                const SizedBox(height: 24),
                _buildActionButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.violet],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.bolt, color: AppColors.bg, size: 26),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SMS Bomber',
                  style:
                      TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              Text('PRO CONTROL PANEL',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.5,
                    color: AppColors.textDim,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.settings_outlined,
              color: AppColors.textDim),
        ),
      ],
    );
  }

  Widget _buildHeroPanel(double progress, int enabledCount) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              PulsingDot(
                color: _isRunning
                    ? AppColors.accent
                    : _done
                        ? AppColors.success
                        : AppColors.textDim,
              ),
              const SizedBox(width: 6),
              Text(
                _isRunning
                    ? 'BOMBING'
                    : _done
                        ? 'COMPLETE'
                        : 'IDLE',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 2.5,
                  fontWeight: FontWeight.w700,
                  color: _isRunning
                      ? AppColors.accent
                      : _done
                          ? AppColors.success
                          : AppColors.textDim,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHi,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '$enabledCount / ${_apis.length} API',
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _statBlock(
                  label: 'SENT',
                  value: _sent,
                  color: AppColors.accent,
                ),
              ),
              Container(
                  width: 1,
                  height: 44,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 16)),
              Expanded(
                child: _statBlock(
                  label: 'FAILED',
                  value: _failed,
                  color: AppColors.danger,
                ),
              ),
              Container(
                  width: 1,
                  height: 44,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(horizontal: 16)),
              Expanded(
                child: _statBlock(
                  label: 'TOTAL',
                  value: int.tryParse(_countCtrl.text) ?? 0,
                  color: AppColors.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (_, v, __) => LinearProgressIndicator(
                value: v,
                minHeight: 8,
                backgroundColor: AppColors.surfaceHi,
                valueColor: const AlwaysStoppedAnimation(AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBlock(
      {required String label,
      required int value,
      required Color color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: AppColors.textDim,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        AnimatedCounter(
          value: value,
          color: color,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  Widget _buildInputCard() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TARGET',
              style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 2.5,
                  color: AppColors.textDim,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8),
            decoration: const InputDecoration(
              hintText: '+1 555 000 0000',
              prefixIcon: Icon(Icons.phone_outlined, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SMS COUNT',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 2.5,
                            color: AppColors.textDim,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _countCtrl,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('THREADS',
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 2.5,
                            color: AppColors.textDim,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _concCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApiSection(int enabledCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('ENDPOINTS',
                style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2.5,
                    color: AppColors.textDim,
                    fontWeight: FontWeight.w700)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addApiDialog(),
              icon: const Icon(Icons.add, size: 18, color: AppColors.accent),
              label: const Text('Add',
                  style: TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ..._apis.asMap().entries.map((entry) {
          final i = entry.key;
          final api = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              borderColor: api.enabled
                  ? AppColors.accent.withOpacity(0.22)
                  : AppColors.border,
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: api.enabled
                          ? AppColors.accent
                          : AppColors.textDim.withOpacity(0.4),
                      boxShadow: api.enabled
                          ? [
                              BoxShadow(
                                color: AppColors.accent.withOpacity(0.7),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _addApiDialog(existing: api, index: i),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(api.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 2),
                          Text(
                            '${api.method}  ·  ${api.url}',
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textDim,
                                fontFamily: 'monospace'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Switch.adaptive(
                    value: api.enabled,
                    activeColor: AppColors.accent,
                    onChanged: (v) {
                      setState(() => _apis[i] = api.copyWith(enabled: v));
                      _saveApis();
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 20, color: AppColors.textDim),
                    onPressed: () {
                      setState(() => _apis.removeAt(i));
                      _saveApis();
                    },
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildActionButton() {
    if (_isRunning) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _stop,
          icon: const Icon(Icons.stop_rounded, size: 24),
          label: const Text('STOP BOMBING',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 0,
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient:
              const LinearGradient(colors: [AppColors.accent, AppColors.violet]),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _start,
          icon: const Icon(Icons.bolt_rounded, size: 24),
          label: const Text('START BOMBING',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.bg,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}