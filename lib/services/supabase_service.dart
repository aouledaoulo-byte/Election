import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ─── Auth ────────────────────────────────────────────────────────────────

  static String? getUserId() {
    return _client.auth.currentUser?.id;
  }

  static Future<AuthResponse> login(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }

  // ─── Agents ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getAgents() async {
    final data = await _client
        .from('agents')
        .select()
        .order('nom', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<List<Map<String, dynamic>>> getAgentsStatus() async {
    final data = await _client
        .from('agents')
        .select('id, nom, prenom, bureau_vote, statut, derniere_connexion')
        .order('statut', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> updateAgentStatus(String agentId, String statut) async {
    await _client
        .from('agents')
        .update({'statut': statut, 'derniere_connexion': DateTime.now().toIso8601String()})
        .eq('id', agentId);
  }

  // ─── Vote Tally ──────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getVoteResults() async {
    final data = await _client
        .from('resultats_votes')
        .select()
        .order('bureau_vote', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> soumettreResultats({
    required String bureauVote,
    required Map<String, int> voix,
    required int votants,
    required int bulletinsNuls,
    required int bulletinsBlancs,
  }) async {
    await _client.from('resultats_votes').upsert({
      'bureau_vote': bureauVote,
      'agent_id': getUserId(),
      'voix': voix,
      'votants': votants,
      'bulletins_nuls': bulletinsNuls,
      'bulletins_blancs': bulletinsBlancs,
      'soumis_le': DateTime.now().toIso8601String(),
      'statut': 'soumis',
    });
  }

  static Future<Map<String, dynamic>> getTotauxNationaux() async {
    final data = await _client
        .from('resultats_votes')
        .select()
        .eq('statut', 'validé');
    
    int totalVotants = 0;
    Map<String, int> totalVoix = {};

    for (final row in data) {
      totalVotants += (row['votants'] as int? ?? 0);
      final voix = row['voix'] as Map<String, dynamic>? ?? {};
      voix.forEach((candidat, v) {
        totalVoix[candidat] = (totalVoix[candidat] ?? 0) + (v as int? ?? 0);
      });
    }

    return {
      'total_votants': totalVotants,
      'total_bureaux': data.length,
      'voix': totalVoix,
    };
  }

  // ─── PV (Procès-Verbaux) ─────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getPVList() async {
    final data = await _client
        .from('proces_verbaux')
        .select()
        .order('cree_le', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> soumettreOuMettreAJourPV({
    required String bureauVote,
    required String statut,
    String? notes,
  }) async {
    await _client.from('proces_verbaux').upsert({
      'bureau_vote': bureauVote,
      'agent_id': getUserId(),
      'statut': statut,
      'notes': notes,
      'cree_le': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> validerPV(String pvId) async {
    await _client
        .from('proces_verbaux')
        .update({
          'statut': 'validé',
          'valide_le': DateTime.now().toIso8601String(),
          'validateur_id': getUserId(),
        })
        .eq('id', pvId);
  }

  static Future<void> rejeterPV(String pvId, String raison) async {
    await _client
        .from('proces_verbaux')
        .update({
          'statut': 'rejeté',
          'raison_rejet': raison,
          'traite_le': DateTime.now().toIso8601String(),
        })
        .eq('id', pvId);
  }

  // ─── Documents ───────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getDocuments() async {
    final data = await _client
        .from('documents')
        .select()
        .order('cree_le', ascending: false);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<String> uploadDocument({
    required String fileName,
    required Uint8List fileBytes,
    required String mimeType,
  }) async {
    final path = '${getUserId()}/$fileName';
    await _client.storage
        .from('documents')
        .uploadBinary(path, fileBytes, fileOptions: FileOptions(contentType: mimeType));

    final url = _client.storage.from('documents').getPublicUrl(path);

    await _client.from('documents').insert({
      'nom_fichier': fileName,
      'url': url,
      'agent_id': getUserId(),
      'cree_le': DateTime.now().toIso8601String(),
    });

    return url;
  }

  static Future<void> supprimerDocument(String docId, String fileName) async {
    final path = '${getUserId()}/$fileName';
    await _client.storage.from('documents').remove([path]);
    await _client.from('documents').delete().eq('id', docId);
  }

  // ─── Messagerie ──────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMessages() async {
    final userId = getUserId();
    final data = await _client
        .from('messages')
        .select()
        .or('expediteur_id.eq.$userId,destinataire_id.eq.$userId,destinataire_id.eq.tous')
        .order('envoye_le', ascending: true);
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<int> getMessagesSent() async {
    final userId = getUserId();
    final data = await _client
        .from('messages')
        .select('id')
        .eq('expediteur_id', userId ?? '');
    return data.length;
  }

  static Future<void> envoyerMessage({
    required String destinataireId,
    required String contenu,
  }) async {
    await _client.from('messages').insert({
      'expediteur_id': getUserId(),
      'destinataire_id': destinataireId,
      'contenu': contenu,
      'envoye_le': DateTime.now().toIso8601String(),
      'lu': false,
    });
  }

  static Future<void> envoyerBroadcast({
    required String contenu,
    required String sujet,
  }) async {
    await _client.from('messages').insert({
      'expediteur_id': getUserId(),
      'destinataire_id': 'tous',
      'sujet': sujet,
      'contenu': contenu,
      'envoye_le': DateTime.now().toIso8601String(),
      'lu': false,
      'est_broadcast': true,
    });
  }

  static Future<void> marquerMessageLu(String messageId) async {
    await _client
        .from('messages')
        .update({'lu': true})
        .eq('id', messageId);
  }

  // ─── Dashboard ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> getStatsDashboard() async {
    final agents = await _client.from('agents').select('id, statut');
    final resultats = await _client.from('resultats_votes').select('id, statut');
    final pvList = await _client.from('proces_verbaux').select('id, statut');
    final messages = await _client
        .from('messages')
        .select('id')
        .eq('lu', false)
        .eq('destinataire_id', getUserId() ?? '');

    final agentsActifs = agents.where((a) => a['statut'] == 'actif').length;
    final bureauxSoumis = resultats.where((r) => r['statut'] == 'soumis').length;
    final bureauxValides = resultats.where((r) => r['statut'] == 'validé').length;
    final pvEnAttente = pvList.where((p) => p['statut'] == 'en_attente').length;

    return {
      'total_agents': agents.length,
      'agents_actifs': agentsActifs,
      'bureaux_soumis': bureauxSoumis,
      'bureaux_valides': bureauxValides,
      'pv_en_attente': pvEnAttente,
      'messages_non_lus': messages.length,
    };
  }
}
