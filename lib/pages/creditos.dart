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
      body: Padding(
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
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/embrapa.png', // Substitua pelo caminho correto do logo da Embrapa
                  height: 50,
                ),
                const SizedBox(width: 16),
                Image.asset(
                  'assets/images/univali.png', // Substitua pelo caminho correto do logo da Univali
                  height: 50,
                ),
              ],
            ),
            const Spacer(),
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
    );
  }
}