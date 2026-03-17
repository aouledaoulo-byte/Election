import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'agents_screen.dart';
import 'vote_tally_screen.dart';
import 'pv_screen.dart';
import 'documents_screen.dart';
import 'messaging_screen.dart';
import 'superviseur_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final stats = await SupabaseService.getStatsDashboard();
      if (mounted) setState(() { _stats = stats; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _logout() async {
    await SupabaseService.logout();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de Bord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    const Text(
                      'Navigation',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildMenuGrid(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF006B3F), Color(0xFF0066CC)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.how_to_vote, color: Colors.white, size: 40),
          SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Élections 2026 — Djibouti',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Système de Surveillance Électorale',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = _stats;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: [
        _statCard('Agents actifs', '${stats?['agents_actifs'] ?? 0}/${stats?['total_agents'] ?? 0}',
            Icons.people, Colors.blue),
        _statCard('Bureaux soumis', '${stats?['bureaux_soumis'] ?? 0}',
            Icons.ballot, Colors.orange),
        _statCard('Bureaux validés', '${stats?['bureaux_valides'] ?? 0}',
            Icons.check_circle, Colors.green),
        _statCard('PV en attente', '${stats?['pv_en_attente'] ?? 0}',
            Icons.pending_actions, Colors.red),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
            Text(label,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid() {
    final items = [
      _MenuItem('Agents', Icons.people, Colors.blue, () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AgentsScreen()))),
      _MenuItem('Dépouillement', Icons.bar_chart, Colors.orange, () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const VoteTallyScreen()))),
      _MenuItem('PV', Icons.description, Colors.green, () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PVScreen()))),
      _MenuItem('Documents', Icons.folder, Colors.purple, () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const DocumentsScreen()))),
      _MenuItem('Messagerie', Icons.message, Colors.teal, () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MessagingScreen()))),
      _MenuItem('Superviseur', Icons.admin_panel_settings, Colors.red, () =>
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperviseurScreen()))),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: items.map((item) => _menuCard(item)).toList(),
    );
  }

  Widget _menuCard(_MenuItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(item.label,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _MenuItem(this.label, this.icon, this.color, this.onTap);
}
