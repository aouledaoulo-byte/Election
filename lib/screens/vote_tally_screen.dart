import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class VoteTallyScreen extends StatefulWidget {
  const VoteTallyScreen({super.key});

  @override
  State<VoteTallyScreen> createState() => _VoteTallyScreenState();
}

class _VoteTallyScreenState extends State<VoteTallyScreen> {
  List<Map<String, dynamic>> _resultats = [];
  Map<String, dynamic>? _totaux;
  bool _loading = true;

  // Formulaire de saisie
  final _bureauCtrl = TextEditingController();
  final _votantsCtrl = TextEditingController();
  final _nulsCtrl = TextEditingController();
  final _blancsCtrl = TextEditingController();
  final Map<String, TextEditingController> _voixCtrl = {
    'Candidat A': TextEditingController(),
    'Candidat B': TextEditingController(),
    'Candidat C': TextEditingController(),
  };
  bool _soumission = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bureauCtrl.dispose();
    _votantsCtrl.dispose();
    _nulsCtrl.dispose();
    _blancsCtrl.dispose();
    _voixCtrl.values.forEach((c) => c.dispose());
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resultats = await SupabaseService.getVoteResults();
      final totaux = await SupabaseService.getTotauxNationaux();
      if (mounted) setState(() {
        _resultats = resultats;
        _totaux = totaux;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _soumettre() async {
    if (_bureauCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le bureau de vote')),
      );
      return;
    }
    setState(() => _soumission = true);
    try {
      final voix = <String, int>{};
      _voixCtrl.forEach((candidat, ctrl) {
        voix[candidat] = int.tryParse(ctrl.text) ?? 0;
      });
      await SupabaseService.soumettreResultats(
        bureauVote: _bureauCtrl.text.trim(),
        voix: voix,
        votants: int.tryParse(_votantsCtrl.text) ?? 0,
        bulletinsNuls: int.tryParse(_nulsCtrl.text) ?? 0,
        bulletinsBlancs: int.tryParse(_blancsCtrl.text) ?? 0,
      );
      _bureauCtrl.clear();
      _votantsCtrl.clear();
      _nulsCtrl.clear();
      _blancsCtrl.clear();
      _voixCtrl.values.forEach((c) => c.clear());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Résultats soumis avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _soumission = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Dépouillement'),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Saisie'),
              Tab(text: 'Résultats'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildSaisie(),
            _buildResultats(),
          ],
        ),
      ),
    );
  }

  Widget _buildSaisie() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Nouveau résultat',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            controller: _bureauCtrl,
            decoration: const InputDecoration(
              labelText: 'Bureau de vote',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _votantsCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nombre de votants',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.people),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Voix par candidat',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._voixCtrl.entries.map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TextField(
              controller: e.value,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: e.key,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.how_to_vote),
              ),
            ),
          )),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nulsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bulletins nuls',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _blancsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bulletins blancs',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _soumission ? null : _soumettre,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006B3F),
                foregroundColor: Colors.white,
              ),
              child: _soumission
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Soumettre les résultats', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultats() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_totaux != null) _totalCard(),
            const SizedBox(height: 16),
            ..._resultats.map(_resultatCard),
          ],
        ),
      ),
    );
  }

  Widget _totalCard() {
    final totaux = _totaux!;
    return Card(
      color: const Color(0xFF006B3F),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Totaux nationaux',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Bureaux validés: ${totaux['total_bureaux']}',
                style: const TextStyle(color: Colors.white70)),
            Text('Total votants: ${totaux['total_votants']}',
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _resultatCard(Map<String, dynamic> r) {
    final statut = r['statut'] as String? ?? '';
    Color statutColor = statut == 'validé' ? Colors.green :
                        statut == 'soumis' ? Colors.orange : Colors.grey;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(r['bureau_vote'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statutColor),
                  ),
                  child: Text(statut,
                      style: TextStyle(color: statutColor, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('Votants: ${r['votants'] ?? 0}',
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
