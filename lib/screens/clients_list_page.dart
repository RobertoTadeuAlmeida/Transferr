import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../models/client.dart';

class ClientsListPage extends StatefulWidget {
  const ClientsListPage({super.key});

  @override
  State<ClientsListPage> createState() => _ClientsListPageState();
}

class _ClientsListPageState extends State<ClientsListPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String userId = ''; // Variável para armazenar o ID do usuário autenticado.

  @override
  void initState() {
    super.initState();
    // Obtém o ID do usuário autenticado
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      userId = currentUser.uid;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clientes Cadastrados'),
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor, // Cor de fundo escura
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Caminho da coleção de clientes no Firestore
        stream: _firestore
            .collection('artifacts')
            .doc(appId)
            .collection('public')
            .doc('data')
            .collection('clients')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar clientes: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF97316)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Nenhum cliente encontrado.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final clients = snapshot.data!.docs
              .map((doc) => Client.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                color: const Color(0xFF2A2A2A),
                // Cartão de cliente mais escuro
                child: InkWell(
                  onTap: () {
                    // Navega para a tela de detalhes do cliente
                    Navigator.pushNamed(
                      context,
                      '/client_details',
                      arguments: client,
                    );
                  },
                  borderRadius: BorderRadius.circular(16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Contato: ${client.contact}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                        Text(
                          'CPF: ${client.cpf}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[400],
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (client.confirmedExcursionIds.isNotEmpty)
                          Text(
                            'Excursões Confirmadas: ${client.confirmedExcursionIds.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.greenAccent,
                            ),
                          ),
                        if (client.pendingExcursionIds.isNotEmpty)
                          Text(
                            'Excursões Pendentes: ${client.pendingExcursionIds.length}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.amberAccent,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Implementar tela para adicionar novo cliente
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Funcionalidade de adicionar cliente em breve!'),
            ),
          );
        },
        label: const Text('Adicionar Cliente'),
        icon: const Icon(Icons.person_add),
        backgroundColor: Theme.of(context).primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
