import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class SuperviseurScreen extends StatefulWidget {
  const SuperviseurScreen({super.key});

  @override
  State<SuperviseurScreen> createState() => _SuperviseurScreenState();
}

class _SuperviseurScreenState extends State<SuperviseurScreen> {
  List<Map<String, dynamic>> _pvEnAttente = [];
  List<Map<String, dynamic>> _agents = [];
  Map<String, dynamic>? _stats;
  bool _loading = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final pvList = await SupabaseService.getPVList();
      final agents = await SupabaseService.getAgentsStatus();
      final stats = await SupabaseService.getStatsDashboard();
      final totaux = await SupabaseService.getTotauxNationaux();
      if (mounted) {
        setState(() {
          _pvEnAttente = pvList.where((p) => p['statut'] == 'en_attente').toList();
          _agents = agents;
          _stats = {...stats, ...totaux};
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _validerPV(String pvId) async {
    try {
      await SupabaseService.validerPV(pvId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PV validé'), backgroundColor: Colors.green),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rejeterPV(String pvId) async {
    final raisonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rejeter le PV'),
        content: TextField(
          controller: raisonCtrl,
          decoration: const InputDecoration(
            labelText: 'Raison du rejet',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Rejeter', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    raisonCtrl.dispose();
    if (confirm != true) return;
    try {
      await SupabaseService.rejeterPV(pvId, raisonCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PV rejeté'), backgroundColor: Colors.orange),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _envoyerBroadcast() async {
    final contenuCtrl = TextEditingController();
    final sujetCtrl = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Broadcast à tous les agents'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sujetCtrl,
              decoration: const InputDecoration(
                labelText: 'Sujet',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contenuCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              if (contenuCtrl.text.trim().isEmpty) return;
              await SupabaseService.envoyerBroadcast(
                contenu: contenuCtrl.text.trim(),
                sujet: sujetCtrl.text.trim().isEmpty ? 'Avis important' : sujetCtrl.text.trim(),
              );
              contenuCtrl.dispose();
              sujetCtrl.dispose();
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Broadcast envoyé'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF006B3F)),
            child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Superviseur'),
        actions: [
          IconButton(
            icon: const Icon(Icons.broadcast_on_personal),
            onPressed: _envoyerBroadcast,
            tooltip: 'Broadcast',
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _selectedTab == 0
                        ? _buildOverview()
                        : _selectedTab == 1
                            ? _buildPVList()
                            : _buildAgentsList(),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    const tabs = ['Aperçu', 'PV', 'Agents'];
    return Container(
      color: Colors.white,
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final selected = e.key == _selectedTab;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected ? const Color(0xFF006B3F) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  e.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? const Color(0xFF006B3F) : Colors.grey,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverview() {
    final stats = _stats;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Vue d\'ensemble nationale',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _statRow('Total agents', '${stats?['total_agents'] ?? 0}', Icons.people, Colors.blue),
          _statRow('Agents actifs', '${stats?['agents_actifs'] ?? 0}', Icons.person, Colors.green),
          _statRow('Bureaux soumis', '${stats?['bureaux_soumis'] ?? 0}', Icons.ballot, Colors.orange),
          _statRow('Bureaux validés', '${stats?['bureaux_valides'] ?? 0}', Icons.check_circle, Colors.green),
          _statRow('PV en attente', '${stats?['pv_en_attente'] ?? 0}', Icons.pending, Colors.red),
          _statRow('Total votants', '${stats?['total_votants'] ?? 0}', Icons.how_to_vote, Colors.purple),
          const SizedBox(height: 20),
          if ((stats?['pv_en_attente'] ?? 0) > 0)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${stats?['pv_en_attente']} PV en attente de validation',
                      style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedTab = 1),
                    child: const Text('Voir'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontSize: 15)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildPVList() {
    if (_pvEnAttente.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('Tous les PV sont traités', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pvEnAttente.length,
      itemBuilder: (_, i) {
        final pv = _pvEnAttente[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.pending_actions, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pv['bureau_vote'] ?? 'Bureau inconnu',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                if (pv['notes'] != null) ...[
                  const SizedBox(height: 6),
                  Text(pv['notes'],
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _rejeterPV(pv['id']),
                        icon: const Icon(Icons.close, size: 18),
                        label: const Text('Rejeter'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _validerPV(pv['id']),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Valider'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAgentsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _agents.length,
      itemBuilder: (_, i) {
        final agent = _agents[i];
        final statut = agent['statut'] as String? ?? 'inconnu';
        Color couleur = statut == 'actif' ? Colors.green :
                        statut == 'en_ligne' ? Colors.blue : Colors.grey;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: couleur.withOpacity(0.15),
              child: Text(
                (agent['nom'] as String? ?? '?')[0].toUpperCase(),
                style: TextStyle(color: couleur, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text('${agent['prenom'] ?? ''} ${agent['nom'] ?? ''}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(agent['bureau_vote'] ?? ''),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: couleur),
              ),
              child: Text(statut,
                  style: TextStyle(color: couleur, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ),
        );
      },
    );
  }
}
