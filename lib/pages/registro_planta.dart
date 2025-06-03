import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrosync/models/plant.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'consulta_tabela.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrosync/models/toast.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:geolocator/geolocator.dart';

class RegistroPlanta extends StatefulWidget {
  final Plant planta;

  const RegistroPlanta({super.key, required this.planta});

  @override
  _RegistroState createState() => _RegistroState();
}

class _RegistroState extends State<RegistroPlanta> {
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _pastureController = TextEditingController();
  final TextEditingController _speciesController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _conditionController = TextEditingController();
  final TextEditingController _cultureController = TextEditingController();
  final TextEditingController _freshWeightController = TextEditingController();
  final TextEditingController _dryWeightController = TextEditingController();

  // Máscaras
  final dateMask = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});
  final quantityMask = MaskTextInputFormatter(mask: '#####', filter: {"#": RegExp(r'[0-9]')});
  final weightMask = MaskTextInputFormatter(mask: '######.##', filter: {"#": RegExp(r'[0-9]')});
  final textMask = MaskTextInputFormatter(mask: 'A'*55, filter: {"A": RegExp(r'[a-zA-ZáéíóúãõâêîôûçÁÉÍÓÚÃÕÂÊÎÔÛÇ ]')});

  var _plantBox = Hive.box('plant_box');

  // Listas fixas originais
  final List<String> _fixedSpeciesList = [
    "Mentrasto",
    "Caruru",
    "Picão",
    "Capim Braquiária",
    "Capim Marmelada",
    "Capim Carrapicho",
    "Trapoeraba",
    "Tiririca",
    "Leiteiro",
    "Erva de Santa Luzia",
    "Cordão de Frade",
    "Joá de Capote",
    "Capim Mombaça",
    "Beldroega",
    "Poaia",
    "Guanxuma",
    "Erva de Touro",
    "Fedegoso",
    "Capim Guiné",
    "Corda de Viola",
    "Buva",
    "Assa-peixe",
    "Sorgo Selvagem",
    "Erva Moura",
    "Serralha",
    "Apaga-fogo",
    "Carrapicho de Carneiro",
    "Vassoura de Bruxa",
    "Vassoura Rabo de Tatu",
    "Capim Colchão",
    "Capim Amargoso",
    "Soja Perene",
    "Losna Branca",
    "Mamona",
    "Malva Preta",
    "Carrapicho Rasteiro",
    "Capim Custodio",
    "Grama Seda",
    "Malva Branca",
    "Sida Rombi",
    "Sida Glaziovi",
    "Sidastrum",
    "Malvastrum",
    "Sida Spinosa",
    "Sida Cordifolia",
    "Cabreuva",
    "Lobeira",
    "Sida Id",
    "Xhantium Stra",
    "Angiquinho",
    "Capim Favorito",
    "Timbete",
    "Chic-chic",
    "Crucifera",
    "Identificas",
    "Botão de Ouro",
    "Quevra Preta",
    "Macela",
  ];
  final List<String> _fixedCultureList = [
    "Soja",
    "Milho",
    "Pasto/Soja",
    "Sorgo/Pasto",
    "Soja/Milho",
    "Milho/Sorgo",
    "Pasto",
    "Sorgo",
    "Milho/Pasto",
    "Pasto/Pasto",
  ];
  final List<String> _fixedConditionList = [
    'Entre-safra',
    'Na colheita',
    'Na lavoura',
    'Pré-dessecação',
  ];
  final List<int> _fixedPastosList = [1, 2, 3, 4]; // Agora é uma lista de int

  // Listas finais (fixas + Firestore)
  List<String> _speciesList = [];
  List<String> _cultureList = [];
  List<String> _conditionList = [];
  List<int> _pastosList = []; // Lista final de int

  @override
  void initState() {
    super.initState();
    _dateController.text = DateFormat('dd/MM/yyyy').format(DateTime.now());
    _fetchDropdownOptions();
  }

  Future<void> _fetchDropdownOptions() async {
    _speciesList = await _getOptionsFromCollection('especies', _fixedSpeciesList);
    _cultureList = await _getOptionsFromCollection('culturas', _fixedCultureList);
    _conditionList = await _getOptionsFromCollection('condicoes', _fixedConditionList);
    _pastosList = await _getPastosOptions();
    setState(() {});
  }

  Future<List<int>> _getPastosOptions() async {
    final snapshot = await FirebaseFirestore.instance.collection('pastos').get();
    final firestoreList = snapshot.docs
        .map((doc) => int.tryParse(doc['nome'].toString().replaceAll(RegExp(r'[^0-9]'), '')))
        .where((v) => v != null)
        .cast<int>()
        .toList();
    final all = {..._fixedPastosList, ...firestoreList}.toList();
    all.sort();
    return all;
  }

  Future<List<String>> _getOptionsFromCollection(String collection, List<String> fixedList) async {
    final snapshot = await FirebaseFirestore.instance.collection(collection).get();
    final firestoreList = snapshot.docs.map((doc) => doc['nome'] as String).toList();
    // Junta e remove duplicatas
    final all = {...fixedList, ...firestoreList}.toList();
    all.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return all;
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
                maskFormatter: dateMask,
              ),
              // Dropdown para Pasto (numérico, mas exibindo "Pasto X")
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pasto',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: int.tryParse(_pastureController.text),
                      items: _pastosList
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text('Pasto $e'),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _pastureController.text = value?.toString() ?? '';
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Selecione o pasto',
                        hintStyle: const TextStyle(color: Colors.black54),
                      ),
                      validator: (value) => value == null ? 'Selecione o pasto.' : null,
                    ),
                  ],
                ),
              ),
              // Novo campo de seleção para a espécie
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nome da espécie',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _speciesController.text.isNotEmpty ? _speciesController.text : null,
                      items: _speciesList
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _speciesController.text = value ?? '';
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Selecione a espécie',
                        hintStyle: const TextStyle(color: Colors.black54),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Selecione a espécie.' : null,
                    ),
                  ],
                ),
              ),
              _buildTextField(
                label: 'Quantidade',
                controller: _quantityController,
                hint: 'Digite a quantidade (Ex: 5)',
                keyboardType: TextInputType.number,
                validator: _quantityValidator,
                maskFormatter: quantityMask,
              ),
              // Campo de seleção para a condição do solo
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Condição do Solo',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _conditionController.text.isNotEmpty ? _conditionController.text : null,
                      items: _conditionList
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _conditionController.text = value ?? '';
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Selecione a condição do solo',
                        hintStyle: const TextStyle(color: Colors.black54),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Selecione a condição do solo.' : null,
                    ),
                  ],
                ),
              ),
              // Campo de seleção para a cultura
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cultura',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _cultureController.text.isNotEmpty ? _cultureController.text : null,
                      items: _cultureList
                          .map((e) => DropdownMenuItem(
                                value: e,
                                child: Text(e),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _cultureController.text = value ?? '';
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        hintText: 'Selecione a cultura',
                        hintStyle: const TextStyle(color: Colors.black54),
                      ),
                      validator: (value) => value == null || value.isEmpty ? 'Selecione a cultura.' : null,
                    ),
                  ],
                ),
              ),
              _buildTextField(
                label: 'Peso Verde (g)',
                controller: _freshWeightController,
                hint: 'Ex: 345.67',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: _optionalWeightValidator,
                maskFormatter: weightMask,
              ),
              _buildTextField(
                label: 'Peso Seco (g)',
                controller: _dryWeightController,
                hint: 'Ex: 145.67',
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                validator: _optionalWeightValidator,
                maskFormatter: weightMask,
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
    MaskTextInputFormatter? maskFormatter,
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
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: maskFormatter != null ? [maskFormatter] : [],
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.black54),
              filled: true,
              fillColor: Colors.white,
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

  Future<void> _savePlantData() async {
    final String date = _dateController.text.trim();
    final String pasture = _pastureController.text.trim();
    final String species = _speciesController.text.trim();
    final int quantity = int.parse(_quantityController.text.trim());
    final String condition = _conditionController.text.trim();
    final String culture = _cultureController.text.trim();
    final double freshWeight = double.tryParse(_freshWeightController.text.trim()) ?? 0.0;
    final double dryWeight = double.tryParse(_dryWeightController.text.trim()) ?? 0.0;

    Position? pos = await _getCurrentLocation();

    if (pos == null) {
      _showSnackbar('Não foi possível obter a localização. Ative o GPS e permita o acesso à localização.');
      return;
    }

    final plantData = {
      "date": date,
      "pasture": pasture,
      "species": species,
      "quantity": quantity,
      "condicaoSolo": condition,
      "culture": culture,
      "fresh_weight": freshWeight,
      "dry_weight": dryWeight,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
    };

    final docRef = await FirebaseFirestore.instance.collection('plants').add(plantData);
    await _plantBox.put(docRef.id, plantData);

    _showSnackbar('Planta salva com sucesso!');
  }

  bool _formIsValid() {
    return _isEmptyValidator(_dateController.text) == null &&
        _isEmptyValidator(_pastureController.text) == null &&
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
      showToast(message: 'Não é permitido repetir a mesma letra mais de 2 vezes consecutivas.');
      return 'Não é permitido repetir a mesma letra mais de 2 vezes consecutivas.';
    }

    return null;
  }

  // Função para obter a localização atual
  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return null;
    }
    return await Geolocator.getCurrentPosition();
  }
}