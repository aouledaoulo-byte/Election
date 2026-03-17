import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class AgentsScreen extends StatefulWidget {
  const AgentsScreen({super.key});

  @override
  State<AgentsScreen> createState() => _AgentsScreenState();
}

class _AgentsScreenState extends State<AgentsScreen> {
  List<Map<String, dynamic>> _agents = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getAgentsStatus();
      if (mounted) {
        setState(() {
          _agents = data;
          _filtered = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _agents.where((a) {
        final nom = '${a['nom']} ${a['prenom']}'.toLowerCase();
        final bureau = (a['bureau_vote'] ?? '').toLowerCase();
        return nom.contains(q) || bureau.contains(q);
      }).toList();
    });
  }

  Color _statusColor(String? statut) {
    switch (statut) {
      case 'actif': return Colors.green;
      case 'inactif': return Colors.grey;
      case 'en_ligne': return Colors.blue;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agents'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher un agent...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${_filtered.length} agent(s)',
                    style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? const Center(child: Text('Aucun agent trouvé'))
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _agentCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _agentCard(Map<String, dynamic> agent) {
    final statut = agent['statut'] as String? ?? 'inconnu';
    final couleur = _statusColor(statut);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        subtitle: Text(agent['bureau_vote'] ?? 'Bureau non assigné'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: couleur.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: couleur, width: 1),
          ),
          child: Text(
            statut,
            style: TextStyle(color: couleur, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
