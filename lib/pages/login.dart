import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'home_page.dart';
import 'signup.dart'; 
import 'package:agrosync/firebase_auth_implementation/firebase_auth_services.dart';
import 'package:agrosync/models/toast.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigning = false;
  bool _showPassword = false; // Adicione esta linha
  final FirebaseAuthService _auth = FirebaseAuthService();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signIn() async {
    setState(() {
      _isSigning = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;

    User? user = await _auth.signInWithEmailAndPassword(email, password);

    setState(() {
      _isSigning = false;
    });

    if (user != null) {
      showToast(message: "Login feito com sucesso!");
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
    } else {
      showToast(message: "Ocorreu um erro");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true, // Permite que o conteúdo suba com o teclado
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              _buildLogo(),
              const SizedBox(height: 20),
              _buildTextField(controller: _emailController, label: 'Email', obscureText: false),
              const SizedBox(height: 20),
              _buildTextField(
                controller: _passwordController,
                label: 'Senha',
                obscureText: !_showPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _showPassword = !_showPassword;
                    });
                  },
                ),
              ),
              const SizedBox(height: 40),
              _buildElevatedButton(label: 'Login', onPressed: () => _signIn(), isPrimary: true),
              const SizedBox(height: 20),
              _buildElevatedButton(label: 'Cadastrar-se', onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
              }),
              const SizedBox(height: 20),
              _buildSponsors(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
  return SizedBox(
    height: 300,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Image.asset(
          'assets/images/agro_sync_verde.png',
          height: 300, 
          fit: BoxFit.contain,
        ),
      ],
    ),
  );
}

  Widget _buildSponsors() {
  return SizedBox(
    height: 100,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Image.asset(
          'assets/images/embrapa.png',
          height: 50, 
          fit: BoxFit.contain,
        ),
        Image.asset(
          'assets/images/univali.png',
          height: 50, 
          fit: BoxFit.contain,
        ),
        Image.asset(
          'assets/images/fapesc.png',
          height: 50, 
          fit: BoxFit.contain,
        ),
        Image.asset(
          'assets/images/cnpq.png',
          height: 50, 
          fit: BoxFit.contain,
        ),
      ],
    ),
  );
}

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required bool obscureText,
    Widget? suffixIcon, // Adicione este parâmetro opcional
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        suffixIcon: suffixIcon, // Adicione esta linha
      ),
      obscureText: obscureText,
    );
  }

  Widget _buildElevatedButton({required String label, required VoidCallback onPressed, bool isPrimary = true}) {
    return SizedBox(
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.black : Colors.grey,
        ),
        child:_isSigning ? CircularProgressIndicator(color: Colors.white,) : Text(
          label,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}
