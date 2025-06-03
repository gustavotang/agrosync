import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreditosPage extends StatelessWidget {
  const CreditosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B8B3B),
        title: const Text('Créditos'),
      ),
      body: SingleChildScrollView( // Adicione este widget
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Creditos',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4B8B3B),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Desenvolvimento:',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B8B3B),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Desenvolvedor',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Produção:',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B8B3B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Orientação:',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B8B3B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Apoiado por:',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4B8B3B),
                ),
              ),
              const SizedBox(height: 50),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/embrapa.png', 
                    height: 100,
                  ),
                  const SizedBox(width: 16),
                  Image.asset(
                    'assets/images/univali.png', 
                    height: 100,
                  ),
                  Image.asset(
                    'assets/images/fapesc.png',
                    height: 100, 
                    fit: BoxFit.contain,
                  ),
                  Image.asset(
                    'assets/images/cnpq.png',
                    height: 100, 
                    fit: BoxFit.contain,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B8B3B),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  ),
                  child: const Text('Voltar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}