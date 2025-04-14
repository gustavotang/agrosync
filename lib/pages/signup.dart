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
  State<SignUpScreen> createState() => _SignUpPageState();
}
class _SignUpPageState extends State<SignUpScreen> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passwordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  bool _isSigningUp = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _signUp() async {

    setState(() {
      _isSigningUp = true;
    });

        String username = _usernameController.text;
        String email = _emailController.text;
        String password = _passwordController.text;

        User? user = await _auth.signUpWithEmailAndPassword(email, password);

    setState(() {
      _isSigningUp = false;
    });
        if (user != null) {
          showToast(message: "Usuario criado com sucesso!");
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomePage()));
        }
      }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Cadastro',
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(controller: _emailController, label: 'Email', obscureText: false),
            const SizedBox(height: 20),
            _buildTextField(controller: _passwordController, label: 'Senha', obscureText: true),
            const SizedBox(height: 20),
            _buildTextField(controller: _confirmPasswordController, label: 'Confirme a Senha', obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _signUp(),
              child:_isSigningUp ? CircularProgressIndicator(color: Colors.black,) : Text(
                'Cadastrar',
                style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.black),
              ),
            ),
          ],
        ),
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
}
