import 'package:agrosync/models/plant.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Importa o Firestore
import 'registro_planta.dart';
import 'consulta_tabela.dart';
import 'package:hive/hive.dart';

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


  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFFFFFFF),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(33.5, 17.2, 27.7, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(0, 0, 0, 242.3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 0, 0, 0.4),
                    width: 54,
                    height: 21,
                    child: SizedBox(
                      width: 28.4,
                      height: 11.1,
                      child: SvgPicture.asset(
                        'assets/vectors/image_6_x2.svg',
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.fromLTRB(0, 0.2, 0, 0),
                    child: SizedBox(
                      width: 66.7,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.fromLTRB(0, 0.3, 5, 0.3),
                            child: SizedBox(
                              width: 17,
                              height: 10.7,
                              child: SvgPicture.asset(
                                'assets/vectors/mobile_signal_5_x2.svg',
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(0, 0, 5, 0.4),
                            child: SizedBox(
                              width: 15.3,
                              height: 11,
                              child: SvgPicture.asset(
                                'assets/vectors/wifi_5_x2.svg',
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                            child: SizedBox(
                              width: 24.3,
                              height: 11.3,
                              child: SvgPicture.asset(
                                'assets/vectors/battery_4_x2.svg',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Botão "Registrar"
            ElevatedButton(
              onPressed: () async {
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

                // Adiciona a nova planta ao Firestore
                //_syncWithFirestore();

                // Navega para a tela de Fase1, se necessário
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistroPlanta(planta: newPlant)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000000),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Registrar',
                style: GoogleFonts.getFont(
                  'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  height: 1.5,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
            ),
            const SizedBox(height: 30), // Espaço entre os botões
            // Botão "Consultar"
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ConsultaTabela()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEEEEEE),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Consultar',
                style: GoogleFonts.getFont(
                  'Inter',
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                  height: 1.5,
                  color: const Color(0xFF000000),
                ),
              ),
            ),
            const Spacer(), // Mantém os botões no topo
          ],
        ),
      ),
    );
  }
}
