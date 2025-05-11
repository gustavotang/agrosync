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
        return plant['Espécie'].toLowerCase().contains(query) || // Alterado de "Nome" para "Espécie"
            plant['Pasto'].toLowerCase().contains(query) ||
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
        "Espécie": item["species"], // Alterado de "Nome" para "Espécie"
        "Pasto": item["pasture"],
        "Cultura": item["culture"],
        "Condição da Área": item["condicaoArea"],
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
    final plant = _filteredPlants[index];
    final TextEditingController dateController =
        TextEditingController(text: plant['Data']);
    final TextEditingController pastureController =
        TextEditingController(text: plant['Pasto']);
    final TextEditingController speciesController =
        TextEditingController(text: plant['Espécie']);
    final TextEditingController quantityController =
        TextEditingController(text: plant['Quantidade'].toString());
    final TextEditingController condicaoAreaController =
        TextEditingController(text: plant['Condição da Área']);
    final TextEditingController cultureController =
        TextEditingController(text: plant['Cultura']);
    final TextEditingController freshWeightController =
        TextEditingController(text: plant['Peso Verde'].toString());
    final TextEditingController dryWeightController =
        TextEditingController(text: plant['Peso Seco'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF4B8B3B), // Fundo verde
          title: const Text(
            'Editar planta',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white, // Texto branco
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField(
                  label: 'Data',
                  controller: dateController,
                  hint: 'DD/MM/AAAA',
                  keyboardType: TextInputType.datetime,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'A data é obrigatória';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Pasto',
                  controller: pastureController,
                  hint: 'Digite o pasto',
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'O pasto é obrigatório';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Nome da espécie',
                  controller: speciesController,
                  hint: 'Digite o nome da espécie',
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'O nome da espécie é obrigatório';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Quantidade',
                  controller: quantityController,
                  hint: 'Digite a quantidade',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'A quantidade é obrigatória';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Condição da Área',
                  controller: condicaoAreaController,
                  hint: 'Digite a condição da área',
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'A condição da área é obrigatória';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Cultura',
                  controller: cultureController,
                  hint: 'Digite a cultura',
                  keyboardType: TextInputType.text,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'A cultura é obrigatória';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Peso Verde (g)',
                  controller: freshWeightController,
                  hint: 'Digite o peso verde',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'O peso verde é obrigatório';
                    }
                    return null;
                  },
                ),
                _buildTextField(
                  label: 'Peso Seco (g)',
                  controller: dryWeightController,
                  hint: 'Digite o peso seco',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'O peso seco é obrigatório';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black, // Texto preto
                backgroundColor: Colors.white, // Fundo branco
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _filteredPlants[index] = {
                    "ID": plant["ID"],
                    "Data": dateController.text,
                    "Pasto": pastureController.text,
                    "Espécie": speciesController.text,
                    "Quantidade": int.tryParse(quantityController.text) ?? 0,
                    "Condição da Área": condicaoAreaController.text,
                    "Cultura": cultureController.text,
                    "Peso Verde": double.tryParse(freshWeightController.text) ?? 0.0,
                    "Peso Seco": double.tryParse(dryWeightController.text) ?? 0.0,
                  };
                  _plantBox.put(plant["ID"], _filteredPlants[index]);
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C), // Verde escuro
                foregroundColor: Colors.white, // Texto branco
              ),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B8B3B), // Fundo verde
      appBar: AppBar(
        title: const Text('Consultar Plantas'),
        backgroundColor: const Color(0xFF388E3C), // Verde escuro
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campos de entrada
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

            // Botões
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Fundo branco
                      foregroundColor: Colors.black, // Texto preto
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
                      backgroundColor: Colors.black, // Fundo preto
                      foregroundColor: Colors.white, // Texto branco
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Procurar'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Título da lista
            const Text(
              'Recente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white, // Texto branco
              ),
            ),
            const SizedBox(height: 8),

            // Lista de plantas
            Expanded(
              child: Container(
                color: Colors.white, // Fundo branco para a lista
                child: ListView.builder(
                  itemCount: _filteredPlants.length,
                  itemBuilder: (context, index) {
                    final plant = _filteredPlants[index];
                    final species = plant['Espécie'] ?? "Espécie não disponível";
                    final date = plant['Data'] ?? "Data não disponível";

                    return ListTile(
                      leading: const Icon(Icons.grass, color: Colors.black),
                      title: Text(
                        species,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black, // Texto preto
                        ),
                      ),
                      subtitle: Text(
                        date,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54, // Texto cinza escuro
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.black),
                        onPressed: () {
                          _editItem(index); // Chama o método _editItem ao clicar no botão
                        },
                      ),
                    );
                  },
                ),
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