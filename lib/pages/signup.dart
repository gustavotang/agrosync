import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart';
import 'package:agrosync/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:agrosync/models/toast.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  static Future<List<String>> fetchStates() async {
    final response = await http.get(Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados'));
    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((state) => state['nome'] as String).toList();
    } else {
      throw Exception('Erro ao buscar estados');
    }
  }

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
  Map<String, String> _stateUfMap = {};
  List<String> _states = [];
  List<String> _cities = [];

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // Notifiers para feedback visual imediato
  final ValueNotifier<String?> _firstNameError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _lastNameError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _cpfError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _phoneError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _birthDateError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _cityError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _stateError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _addressError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _numberError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _zipCodeError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _emailError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _passwordError = ValueNotifier<String?>(null);
  final ValueNotifier<String?> _confirmPasswordError = ValueNotifier<String?>(null);

  @override
  void initState() {
    super.initState();
    _loadStates();

    _firstNameController.addListener(() {
      final text = _firstNameController.text.trim();
      if (text.isEmpty) {
        _firstNameError.value = null;
      } else if (!_isValidName(text)) {
        _firstNameError.value = "Nome inválido";
      } else {
        _firstNameError.value = null;
      }
    });
    _lastNameController.addListener(() {
      final text = _lastNameController.text.trim();
      if (text.isEmpty) {
        _lastNameError.value = null;
      } else if (!_isValidName(text)) {
        _lastNameError.value = "Sobrenome inválido";
      } else {
        _lastNameError.value = null;
      }
    });
    _cpfController.addListener(() {
      final text = _cpfController.text.trim();
      if (text.isEmpty) {
        _cpfError.value = null;
      } else if (!_isValidCPF(text)) {
        _cpfError.value = "CPF inválido";
      } else {
        _cpfError.value = null;
      }
    });
    _phoneController.addListener(() {
      final text = _phoneController.text.trim();
      if (text.isEmpty) {
        _phoneError.value = null;
      } else if (!_isValidPhone(text)) {
        _phoneError.value = "Telefone inválido";
      } else {
        _phoneError.value = null;
      }
    });
    _birthDateController.addListener(() {
      final text = _birthDateController.text.trim();
      if (text.isEmpty) {
        _birthDateError.value = null;
      } else if (!_isValidDate(text)) {
        _birthDateError.value = "Data inválida";
      } else {
        _birthDateError.value = null;
      }
    });
    _cityController.addListener(() {
      _cityError.value = _cityController.text.trim().isEmpty ? "Cidade obrigatória" : null;
    });
    _stateController.addListener(() {
      _stateError.value = _stateController.text.trim().isEmpty ? "Estado obrigatório" : null;
    });
    _addressController.addListener(() {
      _addressError.value = _addressController.text.trim().isEmpty ? "Endereço obrigatório" : null;
    });
    _numberController.addListener(() {
      _numberError.value = _numberController.text.trim().isEmpty ? "Número obrigatório" : null;
    });
    _zipCodeController.addListener(() {
      final text = _zipCodeController.text.trim();
      if (text.isEmpty) {
        _zipCodeError.value = null;
      } else if (!_isValidZipCode(text)) {
        _zipCodeError.value = "CEP inválido";
      } else {
        _zipCodeError.value = null;
      }
    });
    _emailController.addListener(() {
      final text = _emailController.text.trim();
      if (text.isEmpty) {
        _emailError.value = null;
      } else if (!_isValidEmail(text)) {
        _emailError.value = "Email inválido";
      } else {
        _emailError.value = null;
      }
    });
    _passwordController.addListener(() {
      final text = _passwordController.text;
      if (text.isEmpty) {
        _passwordError.value = null;
      } else if (!_isValidPassword(text)) {
        _passwordError.value = "Senha fraca";
      } else {
        _passwordError.value = null;
      }
    });
    _confirmPasswordController.addListener(() {
      final text = _confirmPasswordController.text;
      if (text.isEmpty) {
        _confirmPasswordError.value = null;
      } else if (text != _passwordController.text) {
        _confirmPasswordError.value = "Senhas não coincidem";
      } else {
        _confirmPasswordError.value = null;
      }
    });
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
    _firstNameError.dispose();
    _lastNameError.dispose();
    _cpfError.dispose();
    _phoneError.dispose();
    _birthDateError.dispose();
    _cityError.dispose();
    _stateError.dispose();
    _addressError.dispose();
    _numberError.dispose();
    _zipCodeError.dispose();
    _emailError.dispose();
    _passwordError.dispose();
    _confirmPasswordError.dispose();
    super.dispose();
  }

  void _loadStates() async {
    try {
      final response = await http.get(Uri.parse('https://servicodados.ibge.gov.br/api/v1/localidades/estados'));
      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _stateUfMap = {
            for (var state in data) state['nome']: state['sigla'],
          };
          _states = _stateUfMap.keys.toList();
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

  void _nextPage() {
    if (_validateCurrentPage()) {
      if (_currentPage < 2) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      } else {
        _submitForm();
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
      _signUp();
      showToast(message: "Cadastro realizado com sucesso!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  bool _isValidName(String name) {
    final trimmed = name.trim();

    // Apenas letras e espaços, mínimo 2 letras
    final regex = RegExp(r"^[A-Za-zÀ-ÿ\s]{2,}$");
    if (!regex.hasMatch(trimmed)) return false;

    // Não pode ser só uma letra repetida (ex: aaaaaa)
    if (RegExp(r'^([A-Za-zÀ-ÿ])\1+$').hasMatch(trimmed.replaceAll(' ', ''))) return false;

    // Não pode ser padrão alternado simples (ex: abababab, baba, etc)
    String noSpaces = trimmed.replaceAll(' ', '');
    if (noSpaces.length > 3) {
      // Testa padrões de 2 letras alternando
      for (int i = 1; i <= noSpaces.length ~/ 2; i++) {
        String pattern = noSpaces.substring(0, i);
        String repeated = pattern * (noSpaces.length ~/ i);
        if (repeated == noSpaces) return false;
      }
    }

    return true;
  }

  bool _validateAllFields() {
    if (_firstNameController.text.trim().isEmpty) {
      showToast(message: "O campo Nome é obrigatório.");
      return false;
    }
    if (!_isValidName(_firstNameController.text.trim())) {
      showToast(message: "O Nome deve conter apenas letras e ter pelo menos 2 caracteres.");
      return false;
    }
    if (_lastNameController.text.trim().isEmpty) {
      showToast(message: "O campo Sobrenome é obrigatório.");
      return false;
    }
    if (!_isValidName(_lastNameController.text.trim())) {
      showToast(message: "O Sobrenome deve conter apenas letras e ter pelo menos 2 caracteres.");
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

  bool _isValidCPF(String cpf) {
    cpf = cpf.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11 || RegExp(r'^(\d)\1*$').hasMatch(cpf)) {
      return false;
    }
    for (int i = 9; i < 11; i++) {
      int sum = 0;
      for (int j = 0; j < i; j++) {
        sum += int.parse(cpf[j]) * ((i + 1) - j);
      }
      int digit = (sum * 10) % 11;
      if (digit == 10) digit = 0;
      if (digit != int.parse(cpf[i])) {
        return false;
      }
    }
    return true;
  }

  bool _isValidPhone(String phone) {
    final regex = RegExp(r'^\(\d{2}\) \d{4,5}-\d{4}$');
    return regex.hasMatch(phone);
  }

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

  bool _isValidZipCode(String zipCode) {
    final regex = RegExp(r'^\d{5}-\d{3}$');
    return regex.hasMatch(zipCode);
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    if (password.length < 8) return false;
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
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
      if (!_isValidName(_firstNameController.text.trim())) {
        showToast(message: "O Nome deve conter apenas letras e ter pelo menos 2 caracteres.");
        return false;
      }
      if (!_isValidName(_lastNameController.text.trim())) {
        showToast(message: "O Sobrenome deve conter apenas letras e ter pelo menos 2 caracteres.");
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
      String email = _emailController.text;
      String password = _passwordController.text;

      User? user = await _auth.signUpWithEmailAndPassword(email, password);

      if (user != null) {
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
          "role": "Operador",
        };

        DatabaseReference databaseRef = FirebaseDatabase.instance.ref("users/${user.uid}");
        await databaseRef.set(userData);

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
      body: SafeArea(
        child: Column(
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
                  SingleChildScrollView(child: _buildFirstPage()),
                  SingleChildScrollView(child: _buildSecondPage()),
                  SingleChildScrollView(child: _buildThirdPage()),
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
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        textStyle: GoogleFonts.inter(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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
      ),
    );
  }

  Widget _buildFirstPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: _firstNameError,
            builder: (context, error, child) {
              return _buildTextField(
                controller: _firstNameController,
                label: 'Nome',
                errorText: error,
              );
            },
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<String?>(
            valueListenable: _lastNameError,
            builder: (context, error, child) {
              return _buildTextField(
                controller: _lastNameController,
                label: 'Sobrenome',
                errorText: error,
              );
            },
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<String?>(
            valueListenable: _cpfError,
            builder: (context, error, child) {
              return _buildTextField(
                controller: _cpfController,
                label: 'CPF',
                maskFormatter: cpfMask,
                errorText: error,
              );
            },
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<String?>(
            valueListenable: _phoneError,
            builder: (context, error, child) {
              return _buildTextField(
                controller: _phoneController,
                label: 'Telefone',
                maskFormatter: phoneMask,
                errorText: error,
              );
            },
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<String?>(
            valueListenable: _birthDateError,
            builder: (context, error, child) {
              return _buildTextField(
                controller: _birthDateController,
                label: 'Data de Nascimento',
                maskFormatter: dateMask,
                errorText: error,
              );
            },
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
          const Text(
            'Estado',
            style: TextStyle(
              fontSize: 22,
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
                child: Text(
                  state,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedState = value;
                _stateController.text = value!;
                _selectedCity = null;
                _cityController.clear();
                _cities = [];
              });
              _loadCities(_stateUfMap[value]!);
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.white),
              ),
            ),
            dropdownColor: const Color(0xFF4B8B3B),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20, // <-- tamanho maior
              fontWeight: FontWeight.w500,
            ),
            selectedItemBuilder: (context) => _states.map((state) {
              return Text(
                state,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20, // <-- tamanho maior
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const Text(
            'Cidade',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String?>(
            valueListenable: _cityError,
            builder: (context, error, child) {
              return DropdownButtonFormField<String>(
                value: _selectedCity,
                items: _cities.map((String city) {
                  return DropdownMenuItem<String>(
                    value: city,
                    child: Text(
                      city,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20, // <-- tamanho maior
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedCity = value;
                    _cityController.text = value ?? '';
                  });
                },
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.white),
                  ),
                  errorText: error,
                ),
                dropdownColor: const Color(0xFF4B8B3B),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20, // <-- tamanho maior
                  fontWeight: FontWeight.w500,
                ),
                selectedItemBuilder: (context) => _cities.map((city) {
                  return Text(
                    city,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20, // <-- tamanho maior
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<String?>(
            valueListenable: _addressError,
            builder: (context, error, child) {
              return _buildTextField(
                controller: _addressController,
                label: 'Endereço',
                errorText: error,
              );
            },
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<String?>(
            valueListenable: _numberError,
            builder: (context, error, child) {
              return _buildTextField(
                controller: _numberController,
                label: 'Número',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                errorText: error,
              );
            },
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
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<String?>(
            valueListenable: _zipCodeError,
            builder: (context, error, child) {
              return _buildTextField(
                controller: _zipCodeController,
                label: 'CEP',
                maskFormatter: zipCodeMask,
                errorText: error,
              );
            },
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
              color: Colors.white70,
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
    MaskTextInputFormatter? maskFormatter,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(
            fontSize: 18,
            color: Colors.white,
          ),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters ??
              (maskFormatter != null ? [maskFormatter] : []),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            errorText: errorText,
            errorStyle: const TextStyle(color: Colors.redAccent),
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
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: !isPasswordVisible,
          style: GoogleFonts.inter(
            fontSize: 18,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.white, width: 2),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
              onPressed: onVisibilityToggle,
            ),
          ),
        ),
      ],
    );
  }
}
