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
  List<Map<String, dynamic>> _filteredPlants = []; // Lista filtrada
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController(); // Controlador de texto para pesquisa

  String? selectedCondition;
  String? selectedPasture;

  final List<String> pastures = <String>['1', '2', '3', '4'];
  final List<String> conditions = [
    'Entre safra',
    'Na lavoura',
    'Pré-dessecação',
    'Na colheita',
  ];
  
  @override
  void initState() {
    super.initState();
    _refreshItems();
    _syncWithFirestore();
    
    // Adiciona um listener para a barra de pesquisa
    _searchController.addListener(() {
      _filterPlants();
    });
  }

  // Filtros
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
    // Carrega todos os dados locais armazenados no Hive
    List<Map<String, dynamic>> hiveItems = _plantBox.values.toList().cast<Map<String, dynamic>>();

    // Verifique se os dados do Hive estão corretos
    print("Dados do Hive antes da sincronização: $hiveItems");

    // Envia cada item do Hive para o Firestore
    for (var item in hiveItems) {
      try {
        // Verifique se o item ainda existe no Firestore, se não, exclua do Hive
        DocumentReference docRef = FirebaseFirestore.instance.collection('plants').doc(item['ID']);
        DocumentSnapshot snapshot = await docRef.get();
        if (!snapshot.exists) {
          // Caso o item ainda exista no Firestore, atualize no Hive
          await _plantBox.put(docRef.id, item); // Atualiza o Hive com o ID do Firestore
        }
      } catch (e) {
        print("Erro ao enviar item para o Firebase: $e");
      }
    }
  }

  // Atualiza os dados locais para evitar duplicação e manter sincronização com Firestore
  Future<void> _updateLocalData(List<Map<String, dynamic>> firestoreItems) async {
    await _plantBox.clear(); // Limpa todos os dados locais
    for (var item in firestoreItems) {
      await _plantBox.add(item); // Armazena dados do Firestore no Hive
    }
    print("Dados locais sincronizados com o Firestore.");
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
      _filteredPlants = _plants; // Inicializa a lista filtrada com todos os itens
      print(_plants.length);
    });
  }

  // Função para editar um item
  void _editItem(int index) async {
    if (index < 0 || index >= _filteredPlants.length) {
      print("Erro: Índice $index fora do intervalo. Tamanho de _filteredPlants: ${_filteredPlants.length}");
      return;
    }

    var currentItem = _filteredPlants[index];
    if (currentItem == null) {
      print("Erro: currentItem está nulo para o índice $index");
      return;
    }

    final TextEditingController _nameController = TextEditingController(text: currentItem['Nome'] ?? '');
    final TextEditingController _speciesController = TextEditingController(text: currentItem['Especie'] ?? '');
    final TextEditingController _pastureController = TextEditingController(text: currentItem['Pasto'] ?? '');
    final TextEditingController _cultureController = TextEditingController(text: currentItem['Cultura'] ?? '');
    final TextEditingController _areaConditionController = TextEditingController(text: currentItem['Condiação de Área'] ?? '');    
    final TextEditingController _quantityController = TextEditingController(text: currentItem['Quantidade']?.toString() ?? '0');
    final TextEditingController _freshWeightController = TextEditingController(text: currentItem['Peso Verde']?.toString() ?? '0.0');
    final TextEditingController _dryWeightController = TextEditingController(text: currentItem['Peso Seco']?.toString() ?? '0.0');

    Future<void> _savePlantData() async {
    final String name = _nameController.text.trim();
    final String species = _speciesController.text.trim();
    final String culture = _cultureController.text.trim();
    final int quantity = int.parse(_quantityController.text.trim());
    final double freshWeight = double.tryParse(_freshWeightController.text.trim()) ?? 0.0;
    final double dryWeight = double.tryParse(_dryWeightController.text.trim()) ?? 0.0;

    final plantData = {
      "name": name,
      "species": species,
      "pasture": selectedPasture,
      "culture": culture,
      "condicaoArea": selectedCondition,
      "quantity": quantity,
      "date": DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
      "fresh_weight": freshWeight,
      "dry_weight": dryWeight,
    };

    await _plantBox.delete(currentItem['ID']);
    _plantBox.add(plantData);
    //await FirebaseFirestore.instance.collection('plants').add(plantData);
    _refreshItems();
    _showSnackbar('Planta atualizada com sucesso!');
  }

    bool _formIsValid() {
    return _isEmptyValidator(_nameController.text) == null &&
        _isEmptyValidator(_speciesController.text) == null &&
        _isEmptyValidator(_cultureController.text) == null &&
        _quantityValidator(_quantityController.text) == null &&
        selectedPasture != null &&
        selectedCondition != null;
  }

    Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildActionButton('Cancelar', Colors.white, () {
            Navigator.of(context).pop();
          }),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton('Salvar', Colors.black, () {
            if (_formIsValid()) {
              _savePlantData();
              Navigator.of(context).pop();
            } else {
              _showSnackbar('Por favor, preencha todos os campos obrigatórios.');
            }
          }),
        ),
      ],
    );
  }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(
                  label: 'Nome *',
                  controller: _nameController,
                  hint: 'Insira o nome da planta',
                  keyboardType: TextInputType.name,
                  validator: _validateCustomString,
                ),
                _buildTextField(
                  label: 'Espécie *',
                  controller: _speciesController,
                  hint: 'Espécie da planta (Ex: Capim-mombaça, capim-massai e capim-tanzânia)',
                  keyboardType: TextInputType.text,
                  validator: _validateCustomString,
                ),
                _buildDropdown(
                  label: 'Pasto *',
                  items: pastures,
                  onChanged: (value) => selectedPasture = value,
                ),
                _buildTextField(
                  label: 'Cultura *',
                  controller: _cultureController,
                  hint: 'Cultura (Ex: Soja, Sorgo e Morango)',
                  keyboardType: TextInputType.name,
                  validator: _validateCustomString,
                ),
                _buildDropdown(
                  label: 'Condição da Área *',
                  items: conditions,
                  onChanged: (value) => selectedCondition = value,
                ),
                _buildTextField(
                  label: 'Quantidade *',
                  controller: _quantityController,
                  hint: 'Quantidade (entre 1 e 100.000)',
                  keyboardType: TextInputType.number,
                  validator: _quantityValidator,
                ),
                _buildTextField(
                  label: 'Peso Verde (g)',
                  controller: _freshWeightController,
                  hint: 'Peso verde (10 a 1.000.000 g)',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: _optionalWeightValidator,
                ),
                _buildTextField(
                  label: 'Peso Seco (g)',
                  controller: _dryWeightController,
                  hint: 'Peso seco (10 a 1.000.000 g)',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  validator: _optionalWeightValidator,
                ),
                Text(
                  'Os campos marcados com (*) são obrigatórios.',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                _buildActionButtons(),
              ],
              ),
            ),
          );
        },
      );
  }

  void _deleteItemHive(int index) async {
    var currentItem = _filteredPlants[index];
    
    // Passo 1: Remover do Hive
    try {
      print("Item deletado do Hive com ID: $currentItem['ID']");
      _plantBox.delete(currentItem['ID']);
      print(_plantBox.get(currentItem['ID']));
      _refreshItems();
      _showSnackbar("Planta deleteda com sucesso");
    } catch (e) {
      print("Erro ao deletar item do Hive: $e");
    }
  }

  void _deleteItemFirebase(String itemId) async {
    // Passo 1: Remover do Firestore
    try {
      await FirebaseFirestore.instance.collection('plants').doc(itemId).delete();
      print("Item deletado do Firebase com ID: $itemId");
    } catch (e) {
      print("Erro ao deletar item do Firebase: $e");
    }

    // Passo 2: Atualizar a UI
    setState(() {
      // Remova o item da lista local (em _plants e _filteredPlants)
      _plants.removeWhere((plant) {
        bool shouldRemove = plant['ID'].toString() == itemId;
        if (shouldRemove) {
          print("Removendo item de _plants: ${plant['ID']}");
        }
        return shouldRemove;
      });

      _filteredPlants.removeWhere((plant) {
        bool shouldRemove = plant['ID'].toString() == itemId;
        if (shouldRemove) {
          print("Removendo item de _filteredPlants: ${plant['ID']}");
        }
        return shouldRemove;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Plantas Registradas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _refreshItems();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Pesquisar plantas',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredPlants.length,
              itemBuilder: (_, index) {
                final plant = _filteredPlants[index];

                return Card(
                  color: const Color.fromARGB(255, 134, 255, 134),
                  margin: const EdgeInsets.all(10),
                  elevation: 3,
                  child: ListTile(
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: plant.entries.map<Widget>((entry) {
                        // Exibe o nome da chave seguido pelo valor do dado
                        return Text('${entry.key}: ${entry.value}');
                      }).toList(),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            _editItem(index);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            _deleteItemHive(index);
                            _deleteItemFirebase(plant['ID'].toString());
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RegistroPlanta(
              planta: Plant(
                name: "",
                species: "",
                date: DateTime.now(),
                pasture: "",
                culture: "",
                condicaoArea: "",
                fresh_weight: 0,
                dry_weight: 0,
                quantity: 0,
              ),
            ),
          ),
        ),
        child: const Icon(Icons.add),
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
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 20)),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: OutlineInputBorder()),
            hint: Text('Selecione $label'),
            items: items.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
            onChanged: onChanged,
            validator: (value) =>
                value == null || value.isEmpty ? 'Por favor, selecione uma opção.' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(vertical: 20.0),
      ),
      child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 18, color: color == Colors.black ? Colors.white : Colors.black)),
    );
  }

  void _showSnackbar(String message) {
    showToast(message: message);
  }

  String? _isEmptyValidator(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Este campo é obrigatório.' : null;

  String? _quantityValidator(String? value) {
  // Verifica se o valor é nulo ou vazio
  if (value == null || value.isEmpty) {
    showToast(message: 'A quantidade não pode estar vazia.');
    return 'A quantidade não pode estar vazia.';
  }

  // Verifica se o valor é um número inteiro válido
  final quantity = int.tryParse(value);
  if (quantity == null) {
    // Se não for um número inteiro, notifica o usuário e retorna uma mensagem
    showToast(message: 'A quantidade deve ser um número válido.');
    return 'A quantidade deve ser um número válido.';
  }

  // Verifica se a quantidade está dentro do limite permitido (1 a 100000)
  if (quantity == 0 || quantity > 100000) {
    showToast(message: 'A quantidade deve estar entre 1 e 100.000.');
    return 'A quantidade deve estar entre 1 e 100.000.';
  }

  // Se passar em todas as verificações, a validação é bem-sucedida
  return null;
}

  String? _optionalWeightValidator(String? value) {
    if (value == null || value.isEmpty) return null;
    final weight = double.tryParse(value);
    if (weight != null) {
      if (weight < 10 || weight > 1000000) {
        return 'O peso deve estar entre 10 g e 1.000.000 g.';
      }
    }
    return null;
  }

   String? _validateCustomString(String? value) {
    if (value == null || value.trim().isEmpty) {
      showToast(message: 'Este campo é obrigatório.');
      return 'Este campo é obrigatório.';
    }

    // Remover espaços extras e normalizar o texto
    String normalizedValue = value.trim();

    // Verificar se o comprimento é maior que 55 caracteres
    if (normalizedValue.length > 55) {
      showToast(message: 'O texto não pode exceder 55 caracteres.');
      return 'O texto não pode exceder 55 caracteres.';
    }

    // Verificar se contém pelo menos uma vogal
    final RegExp hasVowel = RegExp(r'[aeiouAEIOU]');
    if (!hasVowel.hasMatch(normalizedValue)) {
      showToast(message: 'O texto deve conter pelo menos uma vogal.');
      return 'O texto deve conter pelo menos uma vogal.';
    }

    // Verificar repetição de letras consecutivas (não mais que 2 vezes)
    final RegExp repeatedChars = RegExp(r'(.)\1\1'); // Match 3 letras iguais consecutivas
    if (repeatedChars.hasMatch(normalizedValue)) {
      showToast(message: 'Não é permitido repetir a mesma letra mais de 2 vezes consecutivamente.');
      return 'Não é permitido repetir a mesma letra mais de 2 vezes consecutivamente.';
    }

    return null; // Validação passou
  }

}