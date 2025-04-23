import 'package:agrosync/models/plant.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'registro_planta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrosync/models/toast.dart';
import 'home_page.dart';

class ConsultaTabela extends StatefulWidget {
  const ConsultaTabela({super.key});

  @override
  _ConsultaTabelaState createState() => _ConsultaTabelaState();
}

class _ConsultaTabelaState extends State<ConsultaTabela> {
  var _plantBox = Hive.box('plant_box');
  List<Map<String, dynamic>> _plants = [];
  List<Map<String, dynamic>> _filteredPlants = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshItems();
    _syncWithFirestore();

    _searchController.addListener(() {
      _filterPlants();
    });
  }

  void _filterPlants() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      _filteredPlants = _plants.where((plant) {
        return plant['Nome'].toLowerCase().contains(query) ||
            plant['Especie'].toLowerCase().contains(query) ||
            plant['Cultura'].toLowerCase().contains(query) ||
            plant['Data'].toLowerCase().contains(query);
      }).toList();
    });
  }

  void _syncWithFirestore() async {
    List<Map<String, dynamic>> hiveItems = _plantBox.values.toList().cast<Map<String, dynamic>>();

    for (var item in hiveItems) {
      try {
        DocumentReference docRef = FirebaseFirestore.instance.collection('plants').doc(item['ID']);
        DocumentSnapshot snapshot = await docRef.get();
        if (!snapshot.exists) {
          await _plantBox.put(docRef.id, item);
        }
      } catch (e) {
        print("Erro ao enviar item para o Firebase: $e");
      }
    }
  }

  void _refreshItems() {
    final data = _plantBox.keys.map((key) {
      final item = _plantBox.get(key);
      return {
        "ID": key,
        "Nome": item["name"],
        "Especie": item["species"],
        "Pasto": item["pasture"],
        "Cultura": item["culture"],
        "Condiação da Área": item["condicaoArea"],
        "Quantidade": item["quantity"],
        "Data": item["date"],
        "Peso Verde": item["fresh_weight"],
        "Peso Seco": item["dry_weight"],
      };
    }).toList();

    setState(() {
      _plants = data.reversed.toList();
      _filteredPlants = _plants;
    });
  }

  void _editItem(int index) {
    // Implementação da edição do item
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B8B3B),
      appBar: AppBar(
        title: const Text('Consultar Plantas'),
        backgroundColor: const Color(0xFF388E3C),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField(
              label: 'Data',
              controller: TextEditingController(),
              hint: 'DD/MM/AAAA',
              keyboardType: TextInputType.datetime,
              validator: (value) => null,
            ),
            _buildTextField(
              label: 'Pasto',
              controller: TextEditingController(),
              hint: 'Digite o pasto',
              keyboardType: TextInputType.text,
              validator: (value) => null,
            ),
            _buildTextField(
              label: 'Nome da espécie',
              controller: TextEditingController(),
              hint: 'Digite o nome da espécie',
              keyboardType: TextInputType.text,
              validator: (value) => null,
            ),
            _buildTextField(
              label: 'Condição da Área',
              controller: TextEditingController(),
              hint: 'Digite a condição da área',
              keyboardType: TextInputType.text,
              validator: (value) => null,
            ),
            _buildTextField(
              label: 'Cultura',
              controller: TextEditingController(),
              hint: 'Digite a cultura',
              keyboardType: TextInputType.text,
              validator: (value) => null,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ElevatedButton(
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
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _filterPlants();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Procurar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Recente',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredPlants.length,
                itemBuilder: (context, index) {
                  final plant = _filteredPlants[index];
                  return ListTile(
                    leading: const Icon(Icons.grass, color: Colors.black),
                    title: Text(
                      plant['Nome'],
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      plant['Data'],
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.black),
                      onPressed: () {
                        _editItem(index);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required TextInputType keyboardType,
    required String? Function(String?) validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Colors.white, // Labels em branco
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.white, // Preenchimento branco
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validator,
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    showToast(message: message);
  }
}