import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/supabase_service.dart';

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});

  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  List<Map<String, dynamic>> _docs = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseService.getDocuments();
      if (mounted) setState(() { _docs = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _upload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if (file.bytes == null) return;

    setState(() => _uploading = true);
    try {
      await SupabaseService.uploadDocument(
        fileName: file.name,
        fileBytes: file.bytes!,
        mimeType: file.extension == 'pdf' ? 'application/pdf' : 'image/jpeg',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document uploadé'), backgroundColor: Colors.green),
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
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _supprimer(Map<String, dynamic> doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer'),
        content: Text('Supprimer "${doc['nom_fichier']}" ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await SupabaseService.supprimerDocument(doc['id'], doc['nom_fichier']);
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  IconData _fileIcon(String? nom) {
    if (nom == null) return Icons.insert_drive_file;
    if (nom.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (nom.endsWith('.jpg') || nom.endsWith('.jpeg') || nom.endsWith('.png')) return Icons.image;
    if (nom.endsWith('.doc') || nom.endsWith('.docx')) return Icons.article;
    return Icons.insert_drive_file;
  }

  Color _fileColor(String? nom) {
    if (nom == null) return Colors.grey;
    if (nom.endsWith('.pdf')) return Colors.red;
    if (nom.endsWith('.jpg') || nom.endsWith('.jpeg') || nom.endsWith('.png')) return Colors.blue;
    if (nom.endsWith('.doc') || nom.endsWith('.docx')) return Colors.indigo;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Documents'),
        actions: [
          if (_uploading)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _uploading ? null : _upload,
        backgroundColor: const Color(0xFF006B3F),
        child: const Icon(Icons.upload_file, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _docs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text('Aucun document', style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Appuyez sur + pour uploader',
                          style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _docs.length,
                    itemBuilder: (_, i) => _docCard(_docs[i]),
                  ),
                ),
    );
  }

  Widget _docCard(Map<String, dynamic> doc) {
    final nom = doc['nom_fichier'] as String?;
    final couleur = _fileColor(nom);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: couleur.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_fileIcon(nom), color: couleur),
        ),
        title: Text(nom ?? 'Document', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          doc['cree_le'] != null
              ? DateTime.tryParse(doc['cree_le'])?.toLocal().toString().split('.')[0] ?? ''
              : '',
          style: const TextStyle(fontSize: 11),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () => _supprimer(doc),
        ),
      ),
    );
  }
}
