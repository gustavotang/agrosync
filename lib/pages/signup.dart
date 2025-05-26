import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart'; 
import 'package:agrosync/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:agrosync/models/toast.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  // Busca os estados do Brasil
  static Future<List<String>> fetchStates() async {
    final response = await http.get(Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((state) => state['nome'] as String).toList();
    } else {
      throw Exception('Erro ao buscar estados');
    }
  }

  // Busca as cidades de um estado
  static Future<List<String>> fetchCities(String stateUf) async {
    final response = await http.get(Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados/$stateUf/municipios'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((city) => city['nome'] as String).toList();
    } else {
      throw Exception('Erro ao buscar cidades');
    }
  }
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}
class _SignUpScreenState extends State<SignUpScreen> {
  final FirebaseAuthService _auth = FirebaseAuthService();
  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool _isSigningUp = false;

  // Controllers for the form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _birthDateController = TextEditingController();

  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _stateController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  final TextEditingController _complementController = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final dateMask = MaskTextInputFormatter(mask: '##/##/####', filter: {"#": RegExp(r'[0-9]')});
  final cpfMask = MaskTextInputFormatter(mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  final phoneMask = MaskTextInputFormatter(mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});
  final zipCodeMask = MaskTextInputFormatter(mask: '#####-###', filter: {"#": RegExp(r'[0-9]')});

  String? _selectedState;
  String? _selectedCity;
  Map<String, String> _stateUfMap = {}; // Mapeia o nome do estado para o código UF
  List<String> _states = []; // Lista de nomes dos estados
  List<String> _cities = [];

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  void _loadStates() async {
    try {
      final response = await http.get(Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _stateUfMap = {
            for (var state in data) state['nome']: state['sigla'], // Nome -> UF
          };
          _states = _stateUfMap.keys.toList(); // Apenas os nomes dos estados
        });
      } else {
        throw Exception('Erro ao buscar estados');
      }
    } catch (e) {
      showToast(message: "Erro ao carregar estados: $e");
    }
  }

  void _loadCities(String stateUf) async {
    try {
      final cities = await LocationService.fetchCities(stateUf);
      setState(() {
        _cities = cities;
      });
    } catch (e) {
      showToast(message: "Erro ao carregar cidades: $e");
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cpfController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _addressController.dispose();
    _numberController.dispose();
    _complementController.dispose();
    _zipCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _nextPage() {
  if (_validateCurrentPage()) {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm(); // Chama o método para finalizar o cadastro
    }
  }
}

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void _submitForm() {
  if (_validateAllFields()) {
    _signUp(); // Chama a função para criar o usuário
    // Exibe mensagem de sucesso
    showToast(message: "Cadastro realizado com sucesso!");
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
    );
  }
}

  bool _validateAllFields() {
  // Valida os campos da primeira página
  if (_firstNameController.text.trim().isEmpty) {
    showToast(message: "O campo Nome é obrigatório.");
    return false;
  }
  if (_lastNameController.text.trim().isEmpty) {
    showToast(message: "O campo Sobrenome é obrigatório.");
    return false;
  }
  if (_cpfController.text.trim().isEmpty || !_isValidCPF(_cpfController.text.trim())) {
    showToast(message: "O CPF informado é inválido.");
    return false;
  }
  if (_phoneController.text.trim().isEmpty || !_isValidPhone(_phoneController.text.trim())) {
    showToast(message: "O Telefone informado é inválido. Use o formato (XX) XXXXX-XXXX.");
    return false;
  }
  if (_birthDateController.text.trim().isEmpty || !_isValidDate(_birthDateController.text.trim())) {
    showToast(message: "A Data de Nascimento informada é inválida. Use o formato DD/MM/AAAA.");
    return false;
  }

  // Valida os campos da segunda página
  if (_cityController.text.trim().isEmpty) {
    showToast(message: "O campo Cidade é obrigatório.");
    return false;
  }
  if (_stateController.text.trim().isEmpty) {
    showToast(message: "O campo Estado é obrigatório.");
    return false;
  }
  if (_addressController.text.trim().isEmpty) {
    showToast(message: "O campo Endereço é obrigatório.");
    return false;
  }
  if (_numberController.text.trim().isEmpty) {
    showToast(message: "O campo Número é obrigatório.");
    return false;
  }
  if (_zipCodeController.text.trim().isEmpty || !_isValidZipCode(_zipCodeController.text.trim())) {
    showToast(message: "O CEP informado é inválido. Use o formato XXXXX-XXX.");
    return false;
  }

  // Valida os campos da terceira página
  if (_emailController.text.trim().isEmpty || !_isValidEmail(_emailController.text.trim())) {
    showToast(message: "O Email informado é inválido.");
    return false;
  }
  if (_passwordController.text.trim().isEmpty) {
    showToast(message: "O campo Senha é obrigatório.");
    return false;
  }
  if (!_isValidPassword(_passwordController.text.trim())) {
    showToast(message: "A senha deve ter pelo menos 8 caracteres, incluindo uma letra maiúscula, uma minúscula, um número e um caractere especial.");
    return false;
  }
  if (_confirmPasswordController.text.trim().isEmpty) {
    showToast(message: "O campo Confirmar Senha é obrigatório.");
    return false;
  }
  if (_passwordController.text.trim() != _confirmPasswordController.text.trim()) {
    showToast(message: "As senhas não coincidem.");
    return false;
  }

  return true;
}

  // Função para validar CPF
  bool _isValidCPF(String cpf) {
    // Remove caracteres não numéricos
    // cpf = cpf.replaceAll(RegExp(r'\D'), '');

    // // if (cpf.length != 11 || RegExp(r'^(\d)\1*$').hasMatch(cpf)) {
    // //   return false; // Verifica se o CPF tem 11 dígitos e não é uma sequência repetida
    // // }

    // // Validação dos dígitos verificadores
    // for (int i = 9; i < 11; i++) {
    //   int sum = 0;
    //   for (int j = 0; j < i; j++) {
    //     sum += int.parse(cpf[j]) * ((i + 1) - j);
    //   }
    //   int digit = (sum * 10) % 11;
    //   if (digit == 10) digit = 0;
    //   if (digit != int.parse(cpf[i])) {
    //     return false;
    //   }
    // }

    return true;
  }

  // Função para validar telefone
  bool _isValidPhone(String phone) {
    final regex = RegExp(r'^\(\d{2}\) \d{4,5}-\d{4}$'); // Formato: (XX) XXXXX-XXXX ou (XX) XXXX-XXXX
    return regex.hasMatch(phone);
  }

  // Função para validar data no formato DD/MM/AAAA
  bool _isValidDate(String date) {
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    if (!regex.hasMatch(date)) return false;

    try {
      final parts = date.split('/');
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);

      final parsedDate = DateTime(year, month, day);
      return parsedDate.day == day && parsedDate.month == month && parsedDate.year == year;
    } catch (e) {
      return false;
    }
  }

  // Função para validar CEP
  bool _isValidZipCode(String zipCode) {
    final regex = RegExp(r'^\d{5}-\d{3}$'); // Formato: XXXXX-XXX
    return regex.hasMatch(zipCode);
  }

  // Função para validar email
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  // Função para validar senha
  bool _isValidPassword(String password) {
    if (password.length < 8) return false; // Mínimo de 8 caracteres
    final hasUppercase = password.contains(RegExp(r'[A-Z]')); // Pelo menos uma letra maiúscula
    final hasLowercase = password.contains(RegExp(r'[a-z]')); // Pelo menos uma letra minúscula
    final hasNumber = password.contains(RegExp(r'[0-9]')); // Pelo menos um número
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')); // Pelo menos um caractere especial

    return hasUppercase && hasLowercase && hasNumber && hasSpecialChar;
  }

  bool _validateCurrentPage() {
  if (_currentPage == 0) {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _cpfController.text.isEmpty ||
        _phoneController.text.isEmpty ||
        _birthDateController.text.isEmpty) {
      showToast(message: "Preencha todos os campos obrigatórios.");
      return false;
    }
  } else if (_currentPage == 1) {
    if (_cityController.text.isEmpty ||
        _stateController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _numberController.text.isEmpty ||
        _zipCodeController.text.isEmpty) {
      showToast(message: "Preencha todos os campos obrigatórios.");
      return false;
    }
  } else if (_currentPage == 2) {
    if (_emailController.text.isEmpty ||
        !_emailController.text.contains('@') ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty ||
        _passwordController.text != _confirmPasswordController.text) {
      showToast(message: "Preencha todos os campos obrigatórios.");
      return false;
    }
  }
  return true;
}

  void _signUp() async {
    setState(() {
      _isSigningUp = true;
    });

    try {
      // Cria o usuário no Firebase Authentication
      String email = _emailController.text;
      String password = _passwordController.text;

      User? user = await _auth.signUpWithEmailAndPassword(email, password);

      if (user != null) {
        // Dados do formulário
        Map<String, dynamic> userData = {
          "firstName": _firstNameController.text.trim(),
          "lastName": _lastNameController.text.trim(),
          "cpf": _cpfController.text.trim(),
          "phone": _phoneController.text.trim(),
          "birthDate": _birthDateController.text.trim(),
          "city": _cityController.text.trim(),
          "state": _stateController.text.trim(),
          "address": _addressController.text.trim(),
          "number": _numberController.text.trim(),
          "complement": _complementController.text.trim().isEmpty ? "" : _complementController.text.trim(),
          "zipCode": _zipCodeController.text.trim(),
          "email": email.trim(),
          "role": "Operador", // Valor padrão para o campo "role"
        };

        // Envia os dados para o Firebase Realtime Database
        DatabaseReference databaseRef = FirebaseDatabase.instance.ref("users/${user.uid}");
        await databaseRef.set(userData);

        // Exibe mensagem de sucesso
        showToast(message: "Usuário criado com sucesso!");
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
      }
    } catch (e) {
      showToast(message: "Erro ao criar usuário: $e");
    } finally {
      if (!mounted) return;
setState(() {
  _isSigningUp = false;
});
    }
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      backgroundColor: const Color(0xFF4B8B3B),
      elevation: 0, 
      toolbarHeight: 50, 
    ),
      backgroundColor: const Color(0xFF4B8B3B),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              children: [
                _buildFirstPage(),
                _buildSecondPage(),
                _buildThirdPage(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentPage > 0)
                  ElevatedButton(
                    onPressed: _previousPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Fundo branco
                      foregroundColor: Colors.black, // Texto preto
                      textStyle: GoogleFonts.inter(
                        fontSize: 22, // Texto maior
                        fontWeight: FontWeight.bold,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40), // Botão maior
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8), // Bordas levemente arredondadas
                      ),
                    ),
                    child: const Text('Voltar'),
                  ),
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black, 
                    foregroundColor: Colors.white, 
                    textStyle: GoogleFonts.inter(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40), 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), 
                    ),
                  ),
                  child: Text(_currentPage < 2 ? 'Próximo' : 'Finalizar'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
  
  Widget _buildFirstPage() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _firstNameController,
          label: 'Nome',
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _lastNameController,
          label: 'Sobrenome',
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _cpfController,
          label: 'CPF',
          maskFormatter: cpfMask, // Máscara de CPF
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _phoneController,
          label: 'Telefone',
          maskFormatter: phoneMask, // Máscara de telefone
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _birthDateController,
          label: 'Data de Nascimento',
          maskFormatter: dateMask, // Máscara de data
        ),
      ],
    ),
  );
}

  Widget _buildSecondPage() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dropdown de Estado
        const Text(
          'Estado',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedState,
          items: _states.map((String state) {
            return DropdownMenuItem<String>(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedState = value;
              _stateController.text = value!; // Atualiza o controlador de texto
            });
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Campo de texto para Cidade
        _buildTextField(
          controller: _cityController,
          label: 'Cidade',
        ),
        const SizedBox(height: 20),

        // Outros campos
        _buildTextField(
          controller: _addressController,
          label: 'Endereço',
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _numberController,
          label: 'Número',
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _complementController,
          label: 'Complemento (opcional)',
        ),
        const SizedBox(height: 8),
        const Text(
          'Este campo é opcional. Preencha apenas se necessário.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70, // Texto em branco com opacidade
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _zipCodeController,
          label: 'CEP',
          maskFormatter: zipCodeMask, // Máscara de CEP
        ),
      ],
    ),
  );
}

  Widget _buildThirdPage() {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email',
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: _passwordController,
          label: 'Senha',
          isPasswordVisible: _isPasswordVisible,
          onVisibilityToggle: () {
            setState(() {
              _isPasswordVisible = !_isPasswordVisible;
            });
          },
        ),
        const SizedBox(height: 8),
        const Text(
          'A senha deve ter pelo menos 8 caracteres, incluindo uma letra maiúscula, uma minúscula, um número e um caractere especial.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70, // Texto em branco com opacidade
          ),
        ),
        const SizedBox(height: 20),
        _buildPasswordField(
          controller: _confirmPasswordController,
          label: 'Confirme a Senha',
          isPasswordVisible: _isConfirmPasswordVisible,
          onVisibilityToggle: () {
            setState(() {
              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
            });
          },
        ),
      ],
    ),
  );
}

  Widget _buildTextField({
  required TextEditingController controller,
  required String label,
  bool obscureText = false,
  MaskTextInputFormatter? maskFormatter, // Adicionado para máscaras
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Título em branco
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        style: GoogleFonts.inter(
          fontSize: 18,
          color: Colors.white, // Texto em branco
        ),
        inputFormatters: maskFormatter != null ? [maskFormatter] : [], // Aplicar máscara
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1), // Fundo semitransparente
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white), // Borda branca
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white), // Borda branca
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 2), // Borda branca ao focar
          ),
        ),
        obscureText: obscureText,
      ),
    ],
  );
}

  Widget _buildPasswordField({
  required TextEditingController controller,
  required String label,
  required bool isPasswordVisible,
  required VoidCallback onVisibilityToggle,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Título em branco
        ),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        obscureText: !isPasswordVisible, // Controla a visibilidade da senha
        style: GoogleFonts.inter(
          fontSize: 18,
          color: Colors.white, // Texto em branco
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.white.withOpacity(0.1), // Fundo semitransparente
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white), // Borda branca
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white), // Borda branca
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 2), // Borda branca ao focar
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white70, // Ícone em branco com opacidade
            ),
            onPressed: onVisibilityToggle, // Alterna a visibilidade
          ),
        ),
      ),
    ],
  );
}

}
