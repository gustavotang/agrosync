import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrosync/models/plant.dart';
import 'package:intl/intl.dart';
import 'home_page.dart';
import 'consulta_tabela.dart';
import 'package:hive/hive.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrosync/models/toast.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';


class RegistroPlanta extends StatefulWidget {
  final Plant planta;

  const RegistroPlanta({super.key, required this.planta});

  @override
  _RegistroState createState() => _RegistroState();
}

class _RegistroState extends State<RegistroPlanta> {
  // Controladores com máscara
  final MaskedTextController _nameController =
      MaskedTextController(mask: '****************'); // Exemplo: limite de 16 caracteres mascarados
  final MaskedTextController _cultureController =
      MaskedTextController(mask: '**********'); // Exemplo: limite de 10 caracteres mascarados
  final MaskedTextController _speciesController =
      MaskedTextController(mask: '**************'); // Exemplo: limite de 14 caracteres mascarados

  // Controladores comuns
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _freshWeightController = TextEditingController();
  final TextEditingController _dryWeightController = TextEditingController();

  var _plantBox = Hive.box('plant_box');

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
  Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text('Cadastrar Planta', style: GoogleFonts.inter(color: Colors.white)),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Campo Nome com máscara
                _buildTextField(
                  label: 'Nome *',
                  controller: _nameController,
                  hint: 'Insira o nome da planta (máx. 16)',
                  keyboardType: TextInputType.name,
                  validator: _validateCustomString,
                ),
                // Campo Espécie com máscara
                _buildTextField(
                  label: 'Espécie *',
                  controller: _speciesController,
                  hint: 'Espécie (máx. 14 caracteres)',
                  keyboardType: TextInputType.text,
                  validator: _validateCustomString,
                ),
                _buildDropdown(
                  label: 'Pasto *',
                  items: pastures,
                  onChanged: (value) => selectedPasture = value,
                ),
                // Campo Cultura com máscara
                _buildTextField(
                  label: 'Cultura *',
                  controller: _cultureController,
                  hint: 'Cultura (máx. 10 caracteres)',
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

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: _buildActionButton('Cancelar', Colors.white, () {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
          }),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton('Salvar', Colors.black, () {
            if (_formIsValid()) {
              _savePlantData();
              Navigator.push(context, MaterialPageRoute(builder: (context) => ConsultaTabela()));
            } else {
              _showSnackbar('Por favor, preencha todos os campos obrigatórios.');
            }
          }),
        ),
      ],
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
      //"docId": docRef.id,
    };

    await _plantBox.add(plantData);
    await FirebaseFirestore.instance.collection('plants').add(plantData);

    _showSnackbar('Planta salva com sucesso!');
  }

  bool _formIsValid() {
    return _isEmptyValidator(_nameController.text) == null &&
        _isEmptyValidator(_speciesController.text) == null &&
        _isEmptyValidator(_cultureController.text) == null &&
        _quantityValidator(_quantityController.text) == null &&
        selectedPasture != null &&
        selectedCondition != null;
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
      if (weight < 0 || weight > 1000000 ) {
        return 'O peso deve estar entre 0,1 g e 1.000.000 g.';
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
