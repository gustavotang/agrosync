import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class AppUser {
  @HiveField(0)
  String id = Uuid().v4();

  @HiveField(1)
  String password;

  @HiveField(2)
  String email;

  final String _baseUrl = 'https://agro-oversight-default-rtdb.firebaseio.com/';

  AppUser({
    required this.password,
    required this.email,
  });

  // Salvar no Firebase
  Future<void> saveToFirebase() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/users.json'),
        body: jsonEncode({
          //"id": id,
          "senha": password,
          "email": email,
        }),
      );
      if (response.statusCode == 200) {
        print('usera salva no Firebase com sucesso.');
      } else {
        print('Erro ao salvar usera no Firebase.');
      }
    } catch (e) {
      print('Erro de conexão: $e');
    }
  }

  // Armazenar localmente usando Hive
  Future<void> saveLocally(Box<AppUser> userBox) async {
    await userBox.add(this);
    print('usera salva localmente.');
  }

  // Sincronizar o Hive com o Firebase
  static Future<void> syncWithFirebase(Box<AppUser> userBox) async {
    final ConnectivityResult connectivityResult = (await Connectivity().checkConnectivity()) as ConnectivityResult;

    if (connectivityResult != ConnectivityResult.none) {
      List<AppUser> users = userBox.values.toList();
      for (var user in users) {
        await user.saveToFirebase();
      }
      await userBox.clear(); // Limpa os dados locais após a sincronização bem-sucedida
      print('Sincronização completa e dados locais removidos.');
    } else {
      print('Sem conexão com a internet. Sincronização pendente.');
    }
  }

  void addUser(AppUser user) {
    if (!Hive.isBoxOpen('userBox')) {
      return;
    }
    var userBox = Hive.box<AppUser>('userBox');
    userBox.add(user); // Add the user to the box
}

  // Função para salvar os dados no Firebase
  Future<void> adduserDB(AppUser user) async {
    final url = Uri.parse('$_baseUrl/new_user.json');  // Defina o caminho do seu database no Firebase

    try {
      final response = await http.post(
        url,
        body: jsonEncode({
          //"id": user.id,
          "password": user.password,
          "email": user.email,
        }),
      );

      if (response.statusCode == 200) {
        print('Dados da usera enviados com sucesso para o Firebase!');
      } else {
        print('Falha ao enviar os dados para o Firebase. Código: ${response.statusCode}');
      }
    } catch (error) {
      print('Erro ao enviar dados para o Firebase: $error');
    }
  }

}
