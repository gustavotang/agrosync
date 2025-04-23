import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'home_page.dart'; 
import 'package:agrosync/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:agrosync/models/toast.dart';

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
  if (_firstNameController.text.isEmpty) {
    showToast(message: "O campo Nome é obrigatório.");
    return false;
  }
  if (_lastNameController.text.isEmpty) {
    showToast(message: "O campo Sobrenome é obrigatório.");
    return false;
  }
  if (_cpfController.text.isEmpty || !_isValidCPF(_cpfController.text)) {
    showToast(message: "O CPF informado é inválido.");
    return false;
  }
  if (_phoneController.text.isEmpty || !_isValidPhone(_phoneController.text)) {
    showToast(message: "O Telefone informado é inválido. Use o formato (XX) XXXXX-XXXX.");
    return false;
  }
  if (_birthDateController.text.isEmpty || !_isValidDate(_birthDateController.text)) {
    showToast(message: "A Data de Nascimento informada é inválida. Use o formato DD/MM/AAAA.");
    return false;
  }

  // Valida os campos da segunda página
  if (_cityController.text.isEmpty) {
    showToast(message: "O campo Cidade é obrigatório.");
    return false;
  }
  if (_stateController.text.isEmpty) {
    showToast(message: "O campo Estado é obrigatório.");
    return false;
  }
  if (_addressController.text.isEmpty) {
    showToast(message: "O campo Endereço é obrigatório.");
    return false;
  }
  if (_numberController.text.isEmpty) {
    showToast(message: "O campo Número é obrigatório.");
    return false;
  }
  if (_zipCodeController.text.isEmpty || !_isValidZipCode(_zipCodeController.text)) {
    showToast(message: "O CEP informado é inválido. Use o formato XXXXX-XXX.");
    return false;
  }

  // Valida os campos da terceira página
  if (_emailController.text.isEmpty || !_isValidEmail(_emailController.text)) {
    showToast(message: "O Email informado é inválido.");
    return false;
  }
  if (_passwordController.text.isEmpty) {
    showToast(message: "O campo Senha é obrigatório.");
    return false;
  }
  if (_confirmPasswordController.text.isEmpty) {
    showToast(message: "O campo Confirmar Senha é obrigatório.");
    return false;
  }
  if (_passwordController.text != _confirmPasswordController.text) {
    showToast(message: "As senhas não coincidem.");
    return false;
  }

  return true;
}

  // Função para validar CPF
  bool _isValidCPF(String cpf) {
    final regex = RegExp(r'^\d{3}\.\d{3}\.\d{3}-\d{2}$');
    return regex.hasMatch(cpf);
  }

  // Função para validar telefone
  bool _isValidPhone(String phone) {
    final regex = RegExp(r'^\(\d{2}\)\d{5}-\d{4}$');
    return regex.hasMatch(phone);
  }

  // Função para validar data no formato DD/MM/AAAA
  bool _isValidDate(String date) {
    final regex = RegExp(r'^\d{2}/\d{2}/\d{4}$');
    return regex.hasMatch(date);
  }

  // Função para validar CEP
  bool _isValidZipCode(String zipCode) {
    final regex = RegExp(r'^\d{5}-\d{3}$');
    return regex.hasMatch(zipCode);
  }

  // Função para validar email
  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return regex.hasMatch(email);
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
          "firstName": _firstNameController.text,
          "lastName": _lastNameController.text,
          "cpf": _cpfController.text,
          "phone": _phoneController.text,
          "birthDate": _birthDateController.text,
          "city": _cityController.text,
          "state": _stateController.text,
          "address": _addressController.text,
          "number": _numberController.text,
          "complement": _complementController.text,
          "zipCode": _zipCodeController.text,
          "email": email,
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
          _buildTextField(controller: _firstNameController, label: 'Nome'),
          const SizedBox(height: 20),
          _buildTextField(controller: _lastNameController, label: 'Sobrenome'),
          const SizedBox(height: 20),
          _buildTextField(controller: _cpfController, label: 'CPF'),
          const SizedBox(height: 20),
          _buildTextField(controller: _phoneController, label: 'Telefone'),
          const SizedBox(height: 20),
          _buildTextField(controller: _birthDateController, label: 'Data de Nascimento'),
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
          _buildTextField(controller: _cityController, label: 'Cidade'),
          const SizedBox(height: 20),
          _buildTextField(controller: _stateController, label: 'Estado'),
          const SizedBox(height: 20),
          _buildTextField(controller: _addressController, label: 'Endereço'),
          const SizedBox(height: 20),
          _buildTextField(controller: _numberController, label: 'Número'),
          const SizedBox(height: 20),
          _buildTextField(controller: _complementController, label: 'Complemento'),
          const SizedBox(height: 20),
          _buildTextField(controller: _zipCodeController, label: 'CEP'),
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
          _buildTextField(controller: _emailController, label: 'Email'),
          const SizedBox(height: 20),
          _buildTextField(controller: _passwordController, label: 'Senha', obscureText: true),
          const SizedBox(height: 20),
          _buildTextField(controller: _confirmPasswordController, label: 'Confirme a Senha', obscureText: true),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, bool obscureText = false}) {
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

}
