import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  final _messageCtrl = TextEditingController();
  final _sujetCtrl = TextEditingController();
  bool _envoi = false;
  bool _isBroadcast = false;
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _sujetCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getMessages();
      if (mounted) {
        setState(() { _messages = data; _loading = false; });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(
              _scrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _envoyer() async {
    if (_messageCtrl.text.trim().isEmpty) return;
    setState(() => _envoi = true);
    try {
      if (_isBroadcast) {
        await SupabaseService.envoyerBroadcast(
          contenu: _messageCtrl.text.trim(),
          sujet: _sujetCtrl.text.trim().isEmpty ? 'Message général' : _sujetCtrl.text.trim(),
        );
      } else {
        await SupabaseService.envoyerMessage(
          destinataireId: 'tous',
          contenu: _messageCtrl.text.trim(),
        );
      }
      _messageCtrl.clear();
      _sujetCtrl.clear();
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _envoi = false);
    }
  }

  bool _isCurrentUser(Map<String, dynamic> msg) {
    return msg['expediteur_id'] == SupabaseService.getUserId();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messagerie'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
          IconButton(
            icon: Icon(_isBroadcast ? Icons.broadcast_on_personal : Icons.person),
            onPressed: () => setState(() => _isBroadcast = !_isBroadcast),
            tooltip: _isBroadcast ? 'Mode broadcast' : 'Mode normal',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isBroadcast)
            Container(
              color: Colors.orange.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.broadcast_on_personal, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Text('Mode broadcast — envoi à tous les agents',
                      style: TextStyle(color: Colors.orange, fontSize: 12)),
                ],
              ),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? const Center(child: Text('Aucun message', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        controller: _scrollCtrl,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _messageBubble(_messages[i]),
                      ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _messageBubble(Map<String, dynamic> msg) {
    final isMine = _isCurrentUser(msg);
    final isBroadcast = msg['est_broadcast'] == true;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isBroadcast
              ? Colors.orange.shade100
              : isMine
                  ? const Color(0xFF006B3F)
                  : Colors.grey.shade200,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isBroadcast && msg['sujet'] != null)
              Text(msg['sujet'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                    fontSize: 12,
                  )),
            Text(
              msg['contenu'] ?? '',
              style: TextStyle(
                color: isMine && !isBroadcast ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isBroadcast)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: _sujetCtrl,
                decoration: const InputDecoration(
                  hintText: 'Sujet du broadcast',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageCtrl,
                  decoration: InputDecoration(
                    hintText: 'Votre message...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    isDense: true,
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.newline,
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                backgroundColor: const Color(0xFF006B3F),
                child: _envoi
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: _envoyer,
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
