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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 40),
            _buildLogo(),
            const SizedBox(height: 20),
            _buildTextField(controller: _emailController, label: 'Email', obscureText: false),
            const SizedBox(height: 20),
            _buildTextField(controller: _passwordController, label: 'Senha', obscureText: true),
            const SizedBox(height: 40),
            _buildElevatedButton(label: 'Login', onPressed: () => _signIn(), isPrimary: true),
            const SizedBox(height: 20),
            _buildElevatedButton(label: 'Cadastrar-se', onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
  return SizedBox(
    height: 100,
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Image.network(
          'https://w7.pngwing.com/pngs/125/1009/png-transparent-brazilian-agricultural-research-corporation-ministry-of-agriculture-cerrado-matopiba-embrapa-agroindustria-tropical-gado-text-trademark-logo.png',
          height: 50, 
          fit: BoxFit.contain,
        ),
        Image.network(
          'https://sescongf.com.br/wp-content/uploads/2019/04/Logo-Univali-final.png',
          height: 50, 
          fit: BoxFit.contain,
        ),
      ],
    ),
  );
}


  Widget _buildTextField({required TextEditingController controller, required String label, required bool obscureText}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
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
