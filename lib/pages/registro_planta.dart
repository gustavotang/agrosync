import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrosync/models/plant.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'consulta_tabela.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrosync/models/toast.dart';

class RegistroPlanta extends StatefulWidget {
  final Plant planta;

  const RegistroPlanta({super.key, required this.planta});

  @override
  _RegistroState createState() => _RegistroState();
}

class _RegistroState extends State<RegistroPlanta> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _cultureController = TextEditingController();
  final TextEditingController _freshWeightController = TextEditingController();
  final TextEditingController _dryWeightController = TextEditingController();

  var _plantBox = Hive.box('plant_box');
  List<Map<String, dynamic>> _pastures = [];
  String? _selectedPastureId;
  List<String> _dropdownFields = [];
  String? _selectedField;

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _loadPastures();
    _loadDropdownFields();
  }

  void _loadPastures() async {
    final pastures = await _fetchPastures();
    setState(() {
      _pastures = pastures;
    });
  }

  void _loadDropdownFields() async {
    final fields = await _fetchDropdownFields();
    setState(() {
      _dropdownFields = fields;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B8B3B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF388E3C),
        title: const Text('Registro de planta'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                label: 'Data',
                controller: _dateController,
                hint: 'DD/MM/AAAA',
                keyboardType: TextInputType.datetime,
                validator: _isEmptyValidator,
              ),
              _buildDropdownField<String>(
                label: 'Pasto',
                value: _selectedPastureId,
                items: _pastures.map((pasture) {
                  return DropdownMenuItem<String>(
                    value: pasture['id'],
                    child: Text(pasture['name']),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPastureId = value;
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecione um pasto.' : null,
              ),
              _buildTextField(
                label: 'Nome da espécie',
                controller: _speciesController,
                hint: 'Digite o nome da espécie',
                keyboardType: TextInputType.text,
                validator: _validateCustomString,
              ),
              _buildTextField(
                label: 'Quantidade',
                controller: _quantityController,
                hint: 'Digite a quantidade',
                keyboardType: TextInputType.number,
                validator: _quantityValidator,
              ),
              _buildTextField(
                label: 'Condição do Solo',
                controller: _conditionController,
                hint: 'Digite a condição do solo',
                keyboardType: TextInputType.text,
                validator: _isEmptyValidator,
              ),
              _buildTextField(
                label: 'Cultura',
                controller: _cultureController,
                hint: 'Digite a cultura',
                keyboardType: TextInputType.text,
                validator: _validateCustomString,
              ),
              _buildTextField(
                label: 'Peso Verde (g)',
                controller: _freshWeightController,
                hint: 'Digite o peso verde',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: _optionalWeightValidator,
              ),
              _buildTextField(
                label: 'Peso Seco (g)',
                controller: _dryWeightController,
                hint: 'Digite o peso seco',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: _optionalWeightValidator,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedField,
                items: _dropdownFields.map((field) {
                  return DropdownMenuItem<String>(
                    value: field,
                    child: Text(field),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedField = value;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Selecione um Campo',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                        if (_formIsValid()) {
                          _savePlantData();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const ConsultaTabela()),
                          );
                        } else {
                          _showSnackbar('Por favor, preencha todos os campos obrigatórios.');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
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

  Widget _buildDropdownField<T>({
    required String label,
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
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
          DropdownButtonFormField<T>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white, // Fundo branco
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  Future<void> _savePlantData() async {
    final String date = _dateController.text.trim();
    final String pastureId = _selectedPastureId!; // Obtém o ID do pasto selecionado
    final String species = _speciesController.text.trim();
    final int quantity = int.parse(_quantityController.text.trim());
    final String condition = _conditionController.text.trim();
    final String culture = _cultureController.text.trim();
    final double freshWeight =
        double.tryParse(_freshWeightController.text.trim()) ?? 0.0;
    final double dryWeight =
        double.tryParse(_dryWeightController.text.trim()) ?? 0.0;

    final plantData = {
      "date": date,
      "pasture_id": pastureId, // Salva o ID do pasto
      "species": species,
      "quantity": quantity,
      "condition": condition,
      "culture": culture,
      "fresh_weight": freshWeight,
      "dry_weight": dryWeight,
    };

    await _plantBox.add(plantData);
    await FirebaseFirestore.instance.collection('plants').add(plantData);

    _showSnackbar('Planta salva com sucesso!');
  }

  bool _formIsValid() {
    return _isEmptyValidator(_dateController.text) == null &&
        _selectedPastureId != null &&
        _validateCustomString(_speciesController.text) == null &&
        _quantityValidator(_quantityController.text) == null &&
        _isEmptyValidator(_conditionController.text) == null &&
        _validateCustomString(_cultureController.text) == null;
  }

  void _showSnackbar(String message) {
    showToast(message: message);
  }

  String? _isEmptyValidator(String? value) =>
      (value == null || value.trim().isEmpty) ? 'Este campo é obrigatório.' : null;

  String? _quantityValidator(String? value) {
    if (value == null || value.isEmpty) {
      showToast(message: 'A quantidade não pode estar vazia.');
      return 'A quantidade não pode estar vazia.';
    }

    final quantity = int.tryParse(value);
    if (quantity == null) {
      showToast(message: 'A quantidade deve ser um número válido.');
      return 'A quantidade deve ser um número válido.';
    }

    if (quantity == 0 || quantity > 100000) {
      showToast(message: 'A quantidade deve estar entre 1 e 100.000.');
      return 'A quantidade deve estar entre 1 e 100.000.';
    }

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

    String normalizedValue = value.trim();

    if (normalizedValue.length > 55) {
      showToast(message: 'O texto não pode exceder 55 caracteres.');
      return 'O texto não pode exceder 55 caracteres.';
    }

    final RegExp hasVowel = RegExp(r'[aeiouAEIOU]');
    if (!hasVowel.hasMatch(normalizedValue)) {
      showToast(message: 'O texto deve conter pelo menos uma vogal.');
      return 'O texto deve conter pelo menos uma vogal.';
    }

    final RegExp repeatedChars = RegExp(r'(.)\1\1');
    if (repeatedChars.hasMatch(normalizedValue)) {
      showToast(message: 'Não é permitido repetir a mesma letra mais de 2 vezes consecutivamente.');
      return 'Não é permitido repetir a mesma letra mais de 2 vezes consecutivamente.';
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchPastures() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('pastures').get();
      return snapshot.docs.map((doc) => {
            'id': doc.id,
            'name': doc['name'],
          }).toList();
    } catch (e) {
      showToast(message: "Erro ao carregar pastos: $e");
      return [];
    }
  }

  Future<List<String>> _fetchDropdownFields() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('dropdown_fields').get();
      return snapshot.docs.map((doc) => doc['name'] as String).toList();
    } catch (e) {
      print('Erro ao buscar campos: $e');
      return [];
    }
  }
}