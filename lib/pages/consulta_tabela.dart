import 'package:agrosync/models/plant.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'registro_planta.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrosync/models/toast.dart';
import 'home_page.dart';
import 'package:flutter/services.dart'; // Adicione este import no topo do arquivo

final dateMask = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});

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

  final TextEditingController _filterDateController = TextEditingController();
  final TextEditingController _filterPastureController = TextEditingController();
  final TextEditingController _filterSpeciesController = TextEditingController();
  final TextEditingController _filterCondicaoSoloController = TextEditingController();
  final TextEditingController _filterCultureController = TextEditingController();

  final List<String> _speciesList = [
    "Mentrasto", "Caruru", "Picão", "Capim Braquiária", "Capim Marmelada", "Capim Carrapicho", "Trapoeraba", "Tiririca",
    "Leiteiro", "Erva de Santa Luzia", "Cordão de Frade", "Joá de Capote", "Capim Mombaça", "Beldroega", "Poaia",
    "Guanxuma", "Erva de Touro", "Fedegoso", "Capim Guiné", "Corda de Viola", "Buva", "Assa-peixe", "Sorgo Selvagem",
    "Erva Moura", "Serralha", "Apaga-fogo", "Carrapicho de Carneiro", "Vassoura de Bruxa", "Vassoura Rabo de Tatu",
    "Capim Colchão", "Capim Amargoso", "Soja Perene", "Losna Branca", "Mamona", "Malva Preta", "Carrapicho Rasteiro",
    "Capim Custodio", "Grama Seda", "Malva Branca", "Sida Rombi", "Sida Glaziovi", "Sidastrum", "Malvastrum",
    "Sida Spinosa", "Sida Cordifolia", "Cabreuva", "Lobeira", "Sida Id", "Xhantium Stra", "Angiquinho", "Capim Favorito",
    "Timbete", "Chic-chic", "Crucifera", "Identificas", "Botão de Ouro", "Quevra Preta", "Macela",
  ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  final List<String> _cultureList = [
    "Soja", "Milho", "Pasto/Soja", "Sorgo/Pasto", "Soja/Milho", "Milho/Sorgo", "Pasto", "Sorgo", "Milho/Pasto", "Pasto/Pasto",
  ]..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  final List<String> _conditionList = [
    'Entre-safra', 'Na colheita', 'Na lavoura', 'Pré-dessecação'
  ];

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
    setState(() {
      _filteredPlants = _plants.where((plant) {
        final matchesDate = _filterDateController.text.isEmpty ||
            (plant['Data']?.toLowerCase().contains(_filterDateController.text.toLowerCase()) ?? false);
        final matchesPasture = _filterPastureController.text.isEmpty ||
            (plant['Pasto']?.toLowerCase().contains(_filterPastureController.text.toLowerCase()) ?? false);
        final matchesSpecies = _filterSpeciesController.text.isEmpty ||
            (plant['Espécie']?.toLowerCase().contains(_filterSpeciesController.text.toLowerCase()) ?? false);
        final matchesCondicao = _filterCondicaoSoloController.text.isEmpty ||
            (plant['Condição do Solo']?.toLowerCase().contains(_filterCondicaoSoloController.text.toLowerCase()) ?? false);
        final matchesCulture = _filterCultureController.text.isEmpty ||
            (plant['Cultura']?.toLowerCase().contains(_filterCultureController.text.toLowerCase()) ?? false);

        return matchesDate && matchesPasture && matchesSpecies && matchesCondicao && matchesCulture;
      }).toList();
    });
  }

  void _syncWithFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('plants').get();
    for (var doc in snapshot.docs) {
      final data = firestoreToHive(doc.data(), doc.id);
      await _plantBox.put(doc.id, data);
    }
    _refreshItems();
  }

  void _refreshItems() {
    final data = _plantBox.keys.map((key) {
      final item = _plantBox.get(key);
      return {
        "ID": key,
        "Espécie": item["Espécie"],
        "Pasto": item["Pasto"],
        "Cultura": item["Cultura"],
        "Condição do Solo": item["Condição do Solo"] ?? item["Condição da Área"],
        "Quantidade": item["Quantidade"],
        "Data": item["Data"],
        "Peso Verde": item["Peso Verde"],
        "Peso Seco": item["Peso Seco"],
      };
    }).toList();

    setState(() {
      _plants = data.reversed.toList();
      _filteredPlants = _plants;
    });
  }

  void _editItem(int index) {
    final plant = _filteredPlants[index];
    final _formKey = GlobalKey<FormState>();

    final TextEditingController dateController =
        TextEditingController(text: plant['Data']);
    final TextEditingController pastureController =
        TextEditingController(text: plant['Pasto']);
    final TextEditingController speciesController =
        TextEditingController(text: plant['Espécie']);
    final TextEditingController quantityController =
        TextEditingController(text: plant['Quantidade'].toString());
    final TextEditingController condicaoSoloController =
        TextEditingController(text: plant['Condição do Solo']);
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
          backgroundColor: const Color(0xFF4B8B3B),
          title: const Text(
            'Editar planta',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
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
                  _buildDropdownField(
                    label: 'Pasto',
                    controller: pastureController,
                    items: List.generate(4, (index) {
                      final value = (index + 1).toString();
                      return DropdownMenuItem(
                        value: value,
                        child: Text('Pasto $value'),
                      );
                    }),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'O pasto é obrigatório';
                      }
                      return null;
                    },
                  ),
                  _buildDropdownField(
                    label: 'Nome da espécie',
                    controller: speciesController,
                    items: _speciesList
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
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
                      if (int.tryParse(value) == null) {
                        return 'Digite um número válido';
                      }
                      return null;
                    },
                  ),
                  _buildDropdownField(
                    label: 'Condição do Solo',
                    controller: condicaoSoloController,
                    items: _conditionList
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'A condição do solo é obrigatória';
                      }
                      return null;
                    },
                  ),
                  _buildDropdownField(
                    label: 'Cultura',
                    controller: cultureController,
                    items: _cultureList
                        .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ))
                        .toList(),
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
                      if (double.tryParse(value) == null) {
                        return 'Digite um número válido';
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
                      if (double.tryParse(value) == null) {
                        return 'Digite um número válido';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.white,
              ),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final updatedPlant = {
                    "ID": plant["ID"],
                    "Data": dateController.text,
                    "Pasto": pastureController.text,
                    "Espécie": speciesController.text,
                    "Quantidade": int.tryParse(quantityController.text) ?? 0,
                    "Condição do Solo": condicaoSoloController.text,
                    "Cultura": cultureController.text,
                    "Peso Verde": double.tryParse(freshWeightController.text) ?? 0.0,
                    "Peso Seco": double.tryParse(dryWeightController.text) ?? 0.0,
                  };

                  setState(() {
                    _plants = _plants.map((p) => p["ID"] == updatedPlant["ID"] ? updatedPlant : p).toList();
                    _filteredPlants = _filteredPlants.map((p) => p["ID"] == updatedPlant["ID"] ? updatedPlant : p).toList();
                    _plantBox.put(updatedPlant["ID"], updatedPlant);
                  });

                  try {
                    final data = hiveToFirestore(updatedPlant);
                    await FirebaseFirestore.instance.collection('plants').doc(updatedPlant["ID"]).set(data);
                  } catch (e) {
                    _showSnackbar("Erro ao atualizar no Firestore: $e");
                  }

                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF388E3C),
                foregroundColor: Colors.white,
              ),
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  // Adicione este método na sua classe _ConsultaTabelaState:
  void _showPlantDetails(Map<String, dynamic> plant) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF388E3C),
          title: Text(
            'Detalhes da Planta',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Espécie', plant['Espécie']),
                _infoRow('Data', plant['Data']),
                _infoRow('Pasto', plant['Pasto']),
                _infoRow('Cultura', plant['Cultura']),
                _infoRow('Condição do Solo', plant['Condição do Solo']),
                _infoRow('Quantidade', plant['Quantidade']?.toString()),
                _infoRow('Peso Verde', plant['Peso Verde']?.toString()),
                _infoRow('Peso Seco', plant['Peso Seco']?.toString()),
                _infoRow(
                  'Localização',
                  'Lat: ${plant['latitude']?.toString() ?? "-"}, Long: ${plant['longitude']?.toString() ?? "-"}',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
              ),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  // Helper para exibir cada linha de informação
  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: GoogleFonts.inter(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF388E3C),
      appBar: AppBar(
        title: const Text(
          'Consultar Plantas',
          style: TextStyle(
            color: Colors.white, // Título branco
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF388E3C),
        iconTheme: const IconThemeData(color: Colors.white),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Atualizar',
            onPressed: () async {
              _syncWithFirestore();
              _showSnackbar("Lista atualizada!");
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Campos de entrada
                _buildTextField(
                  label: 'Data',
                  controller: _filterDateController,
                  hint: 'DD/MM/AAAA',
                  keyboardType: TextInputType.datetime,
                  validator: (value) => null,
                  inputFormatters: [dateMask],
                ),
                _buildDropdownField(
                  label: 'Pasto',
                  controller: _filterPastureController,
                  items: List.generate(4, (index) {
                    final value = (index + 1).toString();
                    return DropdownMenuItem(
                      value: value,
                      child: Text('Pasto $value'),
                    );
                  }),
                  validator: (value) => null,
                ),
                _buildDropdownField(
                  label: 'Nome da espécie',
                  controller: _filterSpeciesController,
                  items: _speciesList
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  validator: (value) => null,
                ),
                _buildDropdownField(
                  label: 'Condição do Solo',
                  controller: _filterCondicaoSoloController,
                  items: _conditionList
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  validator: (value) => null,
                ),
                _buildDropdownField(
                  label: 'Cultura',
                  controller: _filterCultureController,
                  items: _cultureList
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e),
                          ))
                      .toList(),
                  validator: (value) => null,
                ),
                const SizedBox(height: 16),

                // Botões
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          _filterDateController.clear();
                          _filterPastureController.clear();
                          _filterSpeciesController.clear();
                          _filterCondicaoSoloController.clear();
                          _filterCultureController.clear();
                          setState(() {});
                          _filterPlants();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Limpar filtros'),
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

                // Título da lista
                const Text(
                  'Resultado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Texto branco
                  ),
                ),
                const SizedBox(height: 8),

                // Caixa de resultados maior e com scroll
                Container(
                  height: MediaQuery.of(context).size.height * 0.6,
                  color: Colors.white,
                  child: Scrollbar(
                    thumbVisibility: true,
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
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
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            date,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black54,
                            ),
                          ),
                          onTap: () {
                            _showPlantDetails(plant);
                          },
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.black),
                                onPressed: () {
                                  _editItem(index);
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final plant = _filteredPlants[index];
                                  final id = plant["ID"];
                                  print("Tentando deletar planta com ID: $id");

                                  // Remove do Hive
                                  await _plantBox.delete(id);

                                  // Remove do Firestore
                                  try {
                                    await FirebaseFirestore.instance.collection('plants').doc(id).delete();
                                    print("Deletado do Firestore: $id");
                                  } catch (e) {
                                    print("Erro ao deletar do Firestore: $e");
                                    _showSnackbar("Erro ao deletar do Firestore: $e");
                                  }

                                  // Remove das listas
                                  setState(() {
                                    _plants.removeWhere((p) => p["ID"] == id);
                                    _filteredPlants.removeWhere((p) => p["ID"] == id);
                                  });
                                  _showSnackbar("Planta removida com sucesso!");
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    List<TextInputFormatter>? inputFormatters, // <-- Adicione este parâmetro opcional
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
            inputFormatters: inputFormatters, // <-- Use aqui
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

  Widget _buildDropdownField({
    required String label,
    required TextEditingController controller,
    required List<DropdownMenuItem<String>> items,
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
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: getDropdownValue(controller, items),
            items: items,
            onChanged: (value) {
              setState(() {
                controller.text = value ?? '';
              });
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              hintText: 'Selecione uma opção',
              hintStyle: const TextStyle(color: Colors.black54),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    showToast(message: message);
  }

  Map<String, dynamic> hiveToFirestore(Map<String, dynamic> hiveData) {
    return {
      "date": hiveData["Data"],
      "pasture": hiveData["Pasto"],
      "species": hiveData["Espécie"],
      "quantity": hiveData["Quantidade"],
      "condicaoSolo": hiveData["Condição do Solo"],
      "culture": hiveData["Cultura"],
      "fresh_weight": hiveData["Peso Verde"],
      "dry_weight": hiveData["Peso Seco"],
    };
  }

  Map<String, dynamic> firestoreToHive(Map<String, dynamic> firestoreData, String id) {
    return {
      "ID": id,
      "Data": firestoreData["date"],
      "Pasto": firestoreData["pasture"],
      "Espécie": firestoreData["species"],
      "Quantidade": firestoreData["quantity"],
      "Condição do Solo": firestoreData["condicaoSolo"],
      "Cultura": firestoreData["culture"],
      "Peso Verde": firestoreData["fresh_weight"],
      "Peso Seco": firestoreData["dry_weight"],
      "latitude": firestoreData["latitude"],   
      "longitude": firestoreData["longitude"], 
    };
  }

  String? getDropdownValue(TextEditingController controller, List<DropdownMenuItem<String>> items) {
    final value = controller.text;
    if (value.isEmpty) return null;
    final exists = items.any((item) => item.value == value);
    return exists ? value : null;
  }
}