import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';

class ClientRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Retorna uma Stream que notifica sobre qualquer mudança na coleção de clientes
  Stream<List<Client>> getClientsStream() {
    return _firestore.collection('clients').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Client.fromFirestore(doc)).toList();
    });
  }

  // Adiciona um novo cliente
  Future<void> addClient(Client client) {
    return _firestore.collection('clients').add(client.toMap());
  }

  // Atualiza um cliente existente
  Future<void> updateClient(Client client) {
    return _firestore.collection('clients').doc(client.id).update(client.toMap());
  }

  // Deleta um cliente
  Future<void> deleteClient(String clientId) {
    return _firestore.collection('clients').doc(clientId).delete();
  }
}
