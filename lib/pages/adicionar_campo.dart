import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdicionarCampoPage extends StatefulWidget {
  const AdicionarCampoPage({super.key});

  @override
  State<AdicionarCampoPage> createState() => _AdicionarCampoPageState();
}

class _AdicionarCampoPageState extends State<AdicionarCampoPage> {
  final TextEditingController _pastoController = TextEditingController();
  final TextEditingController _especieController = TextEditingController();
  final TextEditingController _condicaoController = TextEditingController();
  final TextEditingController _culturaController = TextEditingController();

  Future<void> _adicionarPasto() async {
    final String pasto = _pastoController.text.trim();
    if (pasto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um nome para o pasto.')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('pastos').add({'nome': pasto});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pasto adicionado!')),
      );
      _pastoController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _adicionarEspecie() async {
    final String especie = _especieController.text.trim();
    if (especie.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um nome para a espécie.')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('especies').add({'nome': especie});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Espécie adicionada!')),
      );
      _especieController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _adicionarCondicao() async {
    final String condicao = _condicaoController.text.trim();
    if (condicao.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite uma condição da área.')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('condicoes').add({'nome': condicao});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Condição adicionada!')),
      );
      _condicaoController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  Future<void> _adicionarCultura() async {
    final String cultura = _culturaController.text.trim();
    if (cultura.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um nome para a cultura.')),
      );
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('culturas').add({'nome': cultura});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cultura adicionada!')),
      );
      _culturaController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B8B3B),
      appBar: AppBar(
        title: const Text('Adicionar Campo'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pasto
              const Text(
                'Pasto',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pastoController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _adicionarPasto,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Adicionar'),
              ),
              const SizedBox(height: 24),

              // Nome da espécie
              const Text(
                'Nome da espécie',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _especieController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _adicionarEspecie,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Adicionar'),
              ),
              const SizedBox(height: 24),

              // Condição da Área
              const Text(
                'Condição da Área',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _condicaoController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _adicionarCondicao,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Adicionar'),
              ),
              const SizedBox(height: 24),

              // Cultura
              const Text(
                'Cultura',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _culturaController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _adicionarCultura,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Adicionar'),
              ),
              const SizedBox(height: 32),

              // Cancelar
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Cancelar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}