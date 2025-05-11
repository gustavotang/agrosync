import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdicionarCampoPage extends StatefulWidget {
  const AdicionarCampoPage({super.key});

  @override
  _AdicionarCampoPageState createState() => _AdicionarCampoPageState();
}

class _AdicionarCampoPageState extends State<AdicionarCampoPage> {
  final TextEditingController _campoController = TextEditingController();

  Future<void> _adicionarCampo() async {
    final String campo = _campoController.text.trim();

    if (campo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O campo não pode estar vazio.')),
      );
      return;
    }

    try {
      // Adiciona o novo campo à coleção "dropdown_fields" no Firestore
      await FirebaseFirestore.instance.collection('dropdown_fields').add({
        'name': campo,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campo adicionado com sucesso!')),
      );

      _campoController.clear(); // Limpa o campo de texto
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar campo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Campo'),
        backgroundColor: const Color(0xFF388E3C), // Verde escuro
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _campoController,
              decoration: InputDecoration(
                labelText: 'Nome do Campo',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _adicionarCampo,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B8B3B), // Verde
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}