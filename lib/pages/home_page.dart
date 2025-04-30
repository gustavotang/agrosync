import 'package:agrosync/models/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa o Firestore
import 'registro_planta.dart';
import 'consulta_tabela.dart';
import 'package:hive/hive.dart';
import 'creditos.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final _firestore = FirebaseFirestore.instance;
  late Box<Map<String, dynamic>> _plantBox;

  // Sincronização com Firestore
  void _syncWithFirestore() async {
    // Carrega todos os dados locais armazenados no Hive
    List<Map<String, dynamic>> hiveItems = _plantBox.values.toList().cast<Map<String, dynamic>>();

    // Verifique se os dados do Hive estão corretos
    print("Dados do Hive antes da sincronização: $hiveItems");

    // Envia cada item do Hive para o Firestore
    for (var item in hiveItems) {
      try {
        // Verifique se o item ainda existe no Firestore, se não, exclua do Hive
        DocumentReference docRef = FirebaseFirestore.instance.collection('plants').doc(item['ID']);
        DocumentSnapshot snapshot = await docRef.get();
        if (!snapshot.exists) {
          // Caso o item ainda exista no Firestore, atualize no Hive
          await _plantBox.put(docRef.id, item); // Atualiza o Hive com o ID do Firestore
        }
      } catch (e) {
        print("Erro ao enviar item para o Firebase: $e");
      }
    }
  }

  Future<void> _updateLocalData(List<Map<String, dynamic>> firestoreItems) async {
    final localDataKeys = _plantBox.keys.toSet();
    final firestoreDataKeys = firestoreItems.map((item) => item["ID"]).toSet();

    // Apaga dados duplicados locais e adiciona os dados do Firestore
    if (localDataKeys.intersection(firestoreDataKeys).isNotEmpty) {
      //await _plantBox.clear();
      for (var item in firestoreItems) {
        await _plantBox.put(item["ID"], item);
      }
    }
  }

  // Função para buscar o total de plantas registradas no Firestore
  Future<int> _getTotalPlants() async {
    final snapshot = await _firestore.collection('plants').get();
    return snapshot.docs.length;
  }

  // Função para buscar o total de usuários cadastrados no Firestore
  Future<int> _getTotalUsers() async {
    final snapshot = await _firestore.collection('users').get();
    return snapshot.docs.length;
  }

  // Função para criar os cartões do dashboard
  Widget _buildDashboardCard({
    required String title,
    required Future<int> futureValue,
  }) {
    return FutureBuilder<int>(
      future: futureValue,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(color: Colors.white);
        }
        if (snapshot.hasError) {
          return const Text(
            'Erro',
            style: TextStyle(color: Colors.white),
          );
        }
        return Column(
          children: [
            Text(
              snapshot.data.toString(),
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: const Color(0xFF4B8B3B), // Fundo verde
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho com informações do usuário
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C), // Verde mais escuro
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.person,
                  color: Colors.white,
                  size: 48,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ADMIN',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Cargo: Administrador',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Dashboard com métricas do Firebase
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: const Color(0xFF388E3C), // Verde mais escuro
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildDashboardCard(
                  title: 'Plantas Registradas',
                  futureValue: _getTotalPlants(),
                ),
                _buildDashboardCard(
                  title: 'Usuários Cadastrados',
                  futureValue: _getTotalUsers(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Título "Serviços"
          Text(
            'Serviços',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Grid com os botões
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildServiceButton(
                  icon: Icons.note_add,
                  label: 'Registrar Planta',
                  onTap: () {
                    Plant newPlant = Plant(
                      name: "capim teste",
                      species: "teste",
                      date: DateTime.now(),
                      pasture: "teste",
                      culture: "teste",
                      condicaoArea: "Em lavoura",
                      fresh_weight: 2,
                      dry_weight: 1.2,
                      quantity: 1,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RegistroPlanta(planta: newPlant),
                      ),
                    );
                  },
                ),
                _buildServiceButton(
                  icon: Icons.search,
                  label: 'Consultar Planta',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConsultaTabela(),
                      ),
                    );
                  },
                ),
                _buildServiceButton(
                  icon: Icons.person,
                  label: 'Creditos',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreditosPage(),
                      ),
                    );
                  },
                ),
                _buildServiceButton(
                  icon: Icons.add_location_alt,
                  label: 'Adicionar Campo',
                  onTap: () {
                    // Ação para o botão "Adicionar Campo"
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Função para criar os botões de serviço
Widget _buildServiceButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      decoration: BoxDecoration(
        color: const Color(0xFF66BB6A), // Verde claro
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.black,
            size: 48,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ),
  );
}



}
