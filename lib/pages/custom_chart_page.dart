import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

class CustomChartPage extends StatefulWidget {
  final FirebaseFirestore firestore;
  const CustomChartPage({super.key, required this.firestore});

  @override
  State<CustomChartPage> createState() => _CustomChartPageState();
}

class _CustomChartPageState extends State<CustomChartPage> {
  String? selectedField1;
  String? selectedField2;
  List<String> fields = [];
  Map<String, int> chartData = {};
  Map<String, Map<String, int>> groupedData = {};
  List<String> secondaryKeys = [];
  final GlobalKey chartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    final snapshot = await widget.firestore.collection('plants').limit(1).get();
    if (snapshot.docs.isNotEmpty) {
      setState(() {
        fields = snapshot.docs.first.data().entries
            .where((e) => e.value is String)
            .map((e) => e.key)
            .toList();
      });
    }
  }

  Future<void> _generateChart() async {
    if (selectedField1 == null) return;
    final snapshot = await widget.firestore.collection('plants').get();
    final List<Map<String, dynamic>> plants =
        snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

    // Se só um campo, gráfico de contagem
    if (selectedField2 == null || selectedField2 == selectedField1) {
      final Map<String, int> data = {};
      for (var plant in plants) {
        final key = plant[selectedField1] ?? 'Desconhecido';
        data[key] = (data[key] ?? 0) + 1;
      }
      setState(() {
        chartData = data;
        groupedData = {};
        secondaryKeys = [];
      });
    } else {
      // Dois campos: se o segundo campo for numérico, some os valores
      bool isNumeric = true;
      for (var plant in plants) {
        final value = plant[selectedField2];
        if (value == null || value is! num) {
          isNumeric = false;
          break;
        }
      }
      if (isNumeric) {
        // Campo Y é numérico: soma os valores para cada categoria do campo X
        final Map<String, num> data = {};
        for (var plant in plants) {
          final keyX = plant[selectedField1] ?? 'Desconhecido';
          final valueY = plant[selectedField2] ?? 0;
          data[keyX] = (data[keyX] ?? 0) + (valueY is num ? valueY : 0);
        }
        setState(() {
          chartData = data.map((k, v) => MapEntry(k, v.toInt()));
          groupedData = {};
          secondaryKeys = [];
        });
      } else {
        // Ambos são texto: gráfico de barras agrupadas (contagem de combinações)
        final Map<String, Map<String, int>> tempGrouped = {};
        final Set<String> tempSecondaryKeys = {};
        for (var plant in plants) {
          final key1 = plant[selectedField1] ?? 'Desconhecido';
          final key2 = plant[selectedField2] ?? 'Desconhecido';
          tempGrouped.putIfAbsent(key1, () => {});
          tempGrouped[key1]![key2] = (tempGrouped[key1]![key2] ?? 0) + 1;
          tempSecondaryKeys.add(key2);
        }
        setState(() {
          groupedData = tempGrouped;
          secondaryKeys = tempSecondaryKeys.toList()..sort();
          chartData = {};
        });
      }
    }
  }

  Future<void> exportChartToPDF(BuildContext context, GlobalKey chartKey, {String fileName = 'grafico.pdf', String? titulo}) async {
    try {
      // Solicita permissão de armazenamento
      if (Platform.isAndroid) {
        var status = await Permission.manageExternalStorage.request();
        if (!status.isGranted) {
          status = await Permission.storage.request();
          if (!status.isGranted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Permissão de armazenamento negada.')),
            );
            return;
          }
        }
      }

      // Captura o gráfico como imagem
      RenderRepaintBoundary boundary = chartKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Cria o PDF
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (titulo != null)
                  pw.Text(titulo, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 16),
                pw.Image(pw.MemoryImage(pngBytes)),
              ],
            );
          },
        ),
      );

      // Salva na pasta Downloads
      final file = File('/storage/emulated/0/Download/$fileName');
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);

      // SnackBar com ação para abrir
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF salvo em: ${file.path}')),
        );
      }

      // Compartilhar automaticamente (opcional)
      await Share.shareXFiles([XFile(file.path)], text: titulo ?? 'Gráfico em PDF');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao exportar gráfico: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF4B8B3B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF4B8B3B),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Gráfico Personalizado',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Como funciona?\n\n'
                    '• Selecione um campo para ver a contagem de cada valor desse campo.\n'
                    '• Se quiser comparar dois campos, selecione um segundo campo. O gráfico mostrará barras agrupadas para cada combinação.\n'
                    '• Clique em "Exportar Gráfico" para gerar um PDF da tabela de dados.\n',
                    style: TextStyle(color: Colors.white, fontSize: 15),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Campo principal:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: selectedField1,
                  items: fields.map((field) {
                    return DropdownMenuItem<String>(
                      value: field,
                      child: Text(
                        field,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedField1 = value;
                      if (selectedField2 == value) selectedField2 = null;
                    });
                  },
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
                  ),
                  dropdownColor: const Color(0xFF4B8B3B),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  iconEnabledColor: Colors.white,
                  selectedItemBuilder: (context) => fields.map((field) {
                    return Text(
                      field,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Campo secundário (opcional):',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: selectedField2,
                  items: fields
                      .where((f) => f != selectedField1)
                      .map((field) {
                    return DropdownMenuItem<String>(
                      value: field,
                      child: Text(
                        field,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedField2 = value;
                    });
                  },
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
                  ),
                  dropdownColor: const Color(0xFF4B8B3B),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  iconEnabledColor: Colors.white,
                  selectedItemBuilder: (context) => fields
                      .where((f) => f != selectedField1)
                      .map((field) {
                    return Text(
                      field,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _generateChart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Gerar Gráfico'),
                ),
                const SizedBox(height: 18),
                if (chartData.isNotEmpty || groupedData.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => exportChartToPDF(context, chartKey),
                        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                        label: const Text('Exportar Gráfico'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (chartData.isNotEmpty)
                  SizedBox(
                    height: 400,
                    child: RepaintBoundary(
                      key: chartKey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: BarChart(
                          BarChartData(
                            barGroups: List.generate(chartData.length, (idx) {
                              final key = chartData.keys.elementAt(idx);
                              return BarChartGroupData(
                                x: idx,
                                barRods: [
                                  BarChartRodData(
                                    toY: chartData[key]!.toDouble(),
                                    color: Colors.blue,
                                    width: 18,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ],
                              );
                            }),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                axisNameWidget: Padding(
                                  padding: const EdgeInsets.only(top: 24.0),
                                  child: Text(
                                    selectedField1 != null
                                        ? selectedField1![0].toUpperCase() + selectedField1!.substring(1)
                                        : 'Campo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx < chartData.length) {
                                      final key = chartData.keys.elementAt(idx);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Transform.rotate(
                                          angle: -0.4,
                                          child: Text(
                                            key,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                axisNameWidget: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    'Quantidade',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 == 0 && value >= 0) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: false),
                            backgroundColor: Colors.transparent,
                            maxY: chartData.values.isNotEmpty
                                ? (chartData.values.reduce((a, b) => a > b ? a : b) + 1).toDouble()
                                : 1,
                            groupsSpace: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (groupedData.isNotEmpty)
                  SizedBox(
                    height: 400,
                    child: RepaintBoundary(
                      key: chartKey,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: BarChart(
                          BarChartData(
                            barGroups: List.generate(groupedData.length, (groupIdx) {
                              final key1 = groupedData.keys.elementAt(groupIdx);
                              return BarChartGroupData(
                                x: groupIdx,
                                barRods: List.generate(secondaryKeys.length, (barIdx) {
                                  final key2 = secondaryKeys[barIdx];
                                  final value = groupedData[key1]?[key2] ?? 0;
                                  return BarChartRodData(
                                    toY: value.toDouble(),
                                    color: Colors.blue[(barIdx + 1) * 200 % 900] ?? Colors.blue,
                                    width: 14,
                                    borderRadius: BorderRadius.circular(4),
                                  );
                                }),
                              );
                            }),
                            titlesData: FlTitlesData(
                              bottomTitles: AxisTitles(
                                axisNameWidget: Padding(
                                  padding: const EdgeInsets.only(top: 24.0),
                                  child: Text(
                                    selectedField1 != null
                                        ? selectedField1![0].toUpperCase() + selectedField1!.substring(1)
                                        : 'Campo',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final idx = value.toInt();
                                    if (idx >= 0 && idx < groupedData.length) {
                                      final key = groupedData.keys.elementAt(idx);
                                      return Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Transform.rotate(
                                          angle: -0.4,
                                          child: Text(
                                            key,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                axisNameWidget: Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: Text(
                                    'Quantidade',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 1,
                                  getTitlesWidget: (value, meta) {
                                    if (value % 1 == 0 && value >= 0) {
                                      return Text(
                                        value.toInt().toString(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      );
                                    }
                                    return const SizedBox.shrink();
                                  },
                                ),
                              ),
                              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            gridData: FlGridData(show: false),
                            backgroundColor: Colors.transparent,
                            maxY: groupedData.values
                                    .expand((e) => e.values)
                                    .fold<int>(0, (prev, el) => el > prev ? el : prev)
                                    .toDouble() +
                                1,
                            groupsSpace: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}