import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final res = await ApiService.get('/auth/me');
      if (res.statusCode == 200) {
        setState(() => _user = jsonDecode(res.body)['user']);
      }
    } catch (e) {
      // ignore
    } finally {
      setState(() => _loading = false);
    }
  }

  Color _scoreColor(int s) {
    if (s >= 750) return const Color(0xFF10B981);
    if (s >= 600) return const Color(0xFF0EA5E9);
    if (s >= 450) return const Color(0xFFF59E0B);
    return const Color(0xFFF43F5E);
  }

  String _scoreLabel(int s) {
    if (s >= 750) return 'Excellent';
    if (s >= 600) return 'Good';
    if (s >= 450) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_user == null) return const Center(child: Text('Failed to load profile'));

    final score = _user!['credit_score'] ?? 500;
    final pct = ((score - 300) / 600 * 100).clamp(0, 100).round();
    final name = _user!['name'] ?? '';
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').join('').toUpperCase();
    final role = _user!['role'] ?? 'member';
    final isActive = _user!['is_active'] == 1;

    return RefreshIndicator(
      onRefresh: _loadUser,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Hero Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade50, Colors.indigo.shade50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                // Avatar
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)]),
                    boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  child: Center(
                    child: Text(initials, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(child: Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: role == 'admin' ? Colors.purple.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(role.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: role == 'admin' ? Colors.purple : Colors.blue)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(_user!['email'] ?? '', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text('$score', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: _scoreColor(score))),
                          const SizedBox(width: 4),
                          Text(_scoreLabel(score), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _scoreColor(score))),
                        ],
                      ),
                    ],
                  ),
                ),
                // Score ring
                SizedBox(
                  width: 64,
                  height: 64,
                  child: CustomPaint(
                    painter: _ScoreRingPainter(pct: pct / 100, color: _scoreColor(score)),
                    child: Center(child: Text('$score', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _scoreColor(score)))),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Account Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.shield, size: 16, color: Colors.blue),
                      ),
                      const SizedBox(width: 8),
                      const Text('Account Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _detailRow(Icons.email, 'Email', _user!['email'] ?? '—'),
                  _detailRow(Icons.phone, 'Phone', _user!['phone']?.toString() ?? '—'),
                  _detailRow(Icons.calendar_today, 'Joined', _formatDate(_user!['joined_date'])),
                  _detailRow(Icons.schedule, 'Member Since', _formatDate(_user!['created_at'])),
                  _detailRow(Icons.shield, 'Role', (role).toString()),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(children: [Icon(Icons.star, size: 16, color: Colors.grey), SizedBox(width: 8), Text('Status', style: TextStyle(fontSize: 14, color: Colors.grey))]),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Credit Score Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(color: _scoreColor(score).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.emoji_events, size: 16, color: _scoreColor(score)),
                      ),
                      const SizedBox(width: 8),
                      const Text('Credit Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Big score
                  Text('$score', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: _scoreColor(score), height: 1)),
                  Text(_scoreLabel(score), style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _scoreColor(score))),
                  Text('out of 900', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  const SizedBox(height: 16),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 10,
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(score)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('300 Poor', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      Text('600 Good', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                      Text('900 Excellent', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Align(alignment: Alignment.centerLeft, child: Text('How to improve', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey))),
                  const SizedBox(height: 8),
                  _scoreTip(true, 'Pay contributions on time', '+10 pts'),
                  _scoreTip(true, 'Repay loans early', '+20 pts'),
                  _scoreTip(false, 'Missed contribution', '−15 pts'),
                  _scoreTip(false, 'Late loan repayment', '−25 pts'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sign out
          FilledButton.icon(
            onPressed: () => context.read<AuthProvider>().logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ]),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
        ],
      ),
    );
  }

  String _formatDate(String? date) {
    if (date == null) return '—';
    final d = DateTime.tryParse(date);
    if (d == null) return date;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Widget _scoreTip(bool good, String text, String delta) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: good ? Colors.green.withOpacity(0.05) : Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: good ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Icon(good ? Icons.check_circle : Icons.cancel, size: 15, color: good ? Colors.green : Colors.red),
            const SizedBox(width: 8),
            Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
          ]),
          Text(delta, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: good ? Colors.green : Colors.red)),
        ],
      ),
    );
  }
}

class _ScoreRingPainter extends CustomPainter {
  final double pct;
  final Color color;

  _ScoreRingPainter({required this.pct, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, bgPaint);

    final fgPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * pct,
      false,
      fgPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) => old.pct != pct || old.color != color;
}
