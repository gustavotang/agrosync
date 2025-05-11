import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';

Future<Map<String, dynamic>?> fetchUserData(String userId) async {
  try {
    DocumentSnapshot snapshot = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (snapshot.exists) {
      return snapshot.data() as Map<String, dynamic>;
    } else {
      print("Usuário não encontrado.");
      return null;
    }
  } catch (e) {
    print("Erro ao buscar dados do usuário: $e");
    return null;
  }
}

Future<List<Map<String, dynamic>>> fetchAllUsers() async {
  try {
    DatabaseReference databaseRef = FirebaseDatabase.instance.ref("users");
    final snapshot = await databaseRef.get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data.values.map((user) => Map<String, dynamic>.from(user)).toList();
    } else {
      print("Nenhum usuário encontrado.");
      return [];
    }
  } catch (e) {
    print("Erro ao buscar usuários: $e");
    return [];
  }
}

class UserProfileScreen extends StatefulWidget {
  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    Map<String, dynamic>? userData = await fetchUserData(userId);

    setState(() {
      _userData = userData;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil do Usuário"),
      ),
      body: _userData == null
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nome: ${_userData!['firstName']} ${_userData!['lastName']}"),
                  Text("CPF: ${_userData!['cpf']}"),
                  Text("Telefone: ${_userData!['phone']}"),
                  Text("Data de Nascimento: ${_userData!['birthDate']}"),
                  Text("Cidade: ${_userData!['city']}"),
                  Text("Estado: ${_userData!['state']}"),
                  Text("Endereço: ${_userData!['address']}"),
                  Text("Número: ${_userData!['number']}"),
                  Text("Complemento: ${_userData!['complement']}"),
                  Text("CEP: ${_userData!['zipCode']}"),
                  Text("Email: ${_userData!['email']}"),
                ],
              ),
            ),
    );
  }
}