import 'package:agrosync/models/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'registro_planta.dart';
import 'consulta_tabela.dart';
import 'adicionar_campo.dart';
import 'package:hive/hive.dart';
import 'creditos.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'custom_chart_page.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final _firestore = FirebaseFirestore.instance;
  
  final GlobalKey chartKey = GlobalKey();
  
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

  // Adicionei a função para contar plantas por pasto
  Map<String, int> _countPlantsByPasture(List<Map<String, dynamic>> plants) {
    final Map<String, int> count = {};
    for (var plant in plants) {
      // Troque 'Pasto' por 'pasture'
      final pasture = plant['pasture'] ?? plant['Pasto'] ?? 'Desconhecido';
      count[pasture] = (count[pasture] ?? 0) + 1;
    }
    return count;
  }

  // Widget do dashboard com gráfico e total de plantas
  Widget _buildDashboardWithChart(BuildContext context, FirebaseFirestore firestore) {
    return FutureBuilder(
      future: firestore.collection('plants').get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Text('Erro ao carregar dados', style: TextStyle(color: Colors.white));
        }
        final docs = (snapshot.data as QuerySnapshot).docs;
        final plants = docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
        final total = plants.length;
        final data = _countPlantsByPasture(plants);
        final keys = data.keys.toList();

        return Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: const Color(0xFF388E3C),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plantas registradas por pasto',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 180,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    barGroups: List.generate(keys.length, (index) {
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: data[keys[index]]!.toDouble(),
                            color: Colors.white,
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx >= 0 && idx < keys.length) {
                              // Exibe "Pasto <nome>" como label
                              return Text(
                                'Pasto ${keys[idx]}',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                                textAlign: TextAlign.center,
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (value, meta) => Text(
                            value.toInt().toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    barTouchData: BarTouchData(enabled: false),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Função para gerar PDF das plantas
  Future<void> exportPlantsToPDF(BuildContext context, List<Map<String, dynamic>> plants) async {
  // Captura o gráfico como imagem
  Uint8List? chartImageBytes;
  try {
    RenderRepaintBoundary boundary = chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    chartImageBytes = byteData?.buffer.asUint8List();
  } catch (e) {
    chartImageBytes = null;
  }

  final pdf = pw.Document();

  pdf.addPage(
    pw.MultiPage(
      build: (pw.Context context) => [
        pw.Text('Relatório Completo de Plantas', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text('Data de geração: ${DateTime.now().toString().substring(0, 16)}'),
        pw.SizedBox(height: 16),
        if (chartImageBytes != null) ...[
          pw.Text('Gráfico: Plantas registradas por pasto', style: pw.TextStyle(fontSize: 18)),
          pw.SizedBox(height: 8),
          pw.Image(pw.MemoryImage(chartImageBytes), height: 200),
          pw.SizedBox(height: 16),
        ],
        pw.Text('Lista completa de plantas:', style: pw.TextStyle(fontSize: 18)),
        pw.SizedBox(height: 8),
        pw.Table.fromTextArray(
          headers: ['Espécie', 'Pasto', 'Cultura', 'Data'],
          data: plants.map((p) => [
            p['Espécie'] ?? '',
            p['Pasto'] ?? '',
            p['Cultura'] ?? '',
            p['Data']?.toString() ?? '',
          ]).toList(),
        ),
      ],
    ),
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
                    FutureBuilder<Map<String, dynamic>?>(
                      future: fetchUserData(FirebaseAuth.instance.currentUser!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator(color: Colors.white);
                        }
                        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
                          return Text(
                            'Usuário não identificado',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          );
                        }
                        final userData = snapshot.data!;
                        final nome = (userData['firstName'] ?? '').toString().trim();
                        final cargo = (userData['role'] ?? '').toString().trim();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nome.isNotEmpty ? nome : 'Usuário não identificado',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Cargo: ${cargo.isNotEmpty ? cargo : 'Não informado'}',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          //Grafico
          _buildDashboardWithChart(context, _firestore),
          
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
                // Removido o card de "Usuários Cadastrados"
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
          const SizedBox(height: 12),

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
                      species: "capim teste",
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
                  onTap: () async {
                    final snapshot = await _firestore.collection('plants').get();
                    final List<Map<String, dynamic>> plants = snapshot.docs.map((doc) {
                      return {
                        "ID": doc.id,
                        "Espécie": doc["species"] ?? "",
                        "Pasto": doc["pasture"] ?? "",
                        "Cultura": doc["culture"] ?? "",
                        "Data": doc["date"] ?? "",
                      };
                    }).toList();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConsultaTabela(),
                      ),
                    );
                  },
                ),
                _buildServiceButton(
                  icon: Icons.picture_as_pdf,
                  label: 'Exportar PDF',
                  onTap: () async {
                    final snapshot = await _firestore.collection('plants').get();
                    final List<Map<String, dynamic>> plants = snapshot.docs.map((doc) {
                      return {
                        "Espécie": doc["species"] ?? "",
                        "Pasto": doc["pasture"] ?? "",
                        "Cultura": doc["culture"] ?? "",
                        "Data": doc["date"] ?? "",
                      };
                    }).toList();
                    await exportPlantsToPDF(context, plants);
                  },
                ),
                _buildServiceButton(
                  icon: Icons.bar_chart,
                  label: 'Gráfico Personalizado',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CustomChartPage(firestore: _firestore),
                      ),
                    );
                  },
                ),
                // Mova estes dois para o final:
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdicionarCampoPage(),
                      ),
                    );
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

Future<Map<String, dynamic>?> fetchUserData(String userId) async {
  try {
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref("users/$userId");
    final snapshot = await databaseRef.get();

    if (snapshot.exists) {
      return Map<String, dynamic>.from(snapshot.value as Map);
    } else {
      print("Usuário não encontrado.");
      return null;
    }
  } catch (e) {
    print("Erro ao buscar dados do usuário: $e");
    return null;
  }
}

void getUserData() async {
  String userId = FirebaseAuth.instance.currentUser!.uid; // Obtém o UID do usuário autenticado
  Map<String, dynamic>? userData = await fetchUserData(userId);

  if (userData != null) {
    print("Dados do usuário: $userData");
  } else {
    print("Nenhum dado encontrado para o usuário.");
  }
}

}
