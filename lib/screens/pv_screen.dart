import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class PVScreen extends StatefulWidget {
  const PVScreen({super.key});

  @override
  State<PVScreen> createState() => _PVScreenState();
}

class _PVScreenState extends State<PVScreen> {
  List<Map<String, dynamic>> _pvList = [];
  bool _loading = true;

  final _bureauCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _soumission = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bureauCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getPVList();
      if (mounted) setState(() { _pvList = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _soumettrePV() async {
    if (_bureauCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez saisir le bureau de vote')),
      );
      return;
    }
    setState(() => _soumission = true);
    try {
      await SupabaseService.soumettreOuMettreAJourPV(
        bureauVote: _bureauCtrl.text.trim(),
        statut: 'en_attente',
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      _bureauCtrl.clear();
      _notesCtrl.clear();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PV soumis'), backgroundColor: Colors.green),
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

  void _afficherFormulaire() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Soumettre un PV',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: _bureauCtrl,
              decoration: const InputDecoration(
                labelText: 'Bureau de vote',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _soumission ? null : _soumettrePV,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006B3F),
                  foregroundColor: Colors.white,
                ),
                child: _soumission
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Soumettre'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String? statut) {
    switch (statut) {
      case 'validé': return Colors.green;
      case 'rejeté': return Colors.red;
      case 'en_attente': return Colors.orange;
      default: return Colors.grey;
    }
  }

  IconData _statusIcon(String? statut) {
    switch (statut) {
      case 'validé': return Icons.check_circle;
      case 'rejeté': return Icons.cancel;
      case 'en_attente': return Icons.pending;
      default: return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Procès-Verbaux'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _afficherFormulaire,
        backgroundColor: const Color(0xFF006B3F),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pvList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.description_outlined, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Aucun PV soumis', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _pvList.length,
                    itemBuilder: (_, i) => _pvCard(_pvList[i]),
                  ),
                ),
    );
  }

  Widget _pvCard(Map<String, dynamic> pv) {
    final statut = pv['statut'] as String?;
    final couleur = _statusColor(statut);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_statusIcon(statut), color: couleur),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(pv['bureau_vote'] ?? 'Bureau inconnu',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (pv['notes'] != null)
                    Text(pv['notes'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: couleur.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: couleur),
              ),
              child: Text(statut ?? '',
                  style: TextStyle(color: couleur, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
