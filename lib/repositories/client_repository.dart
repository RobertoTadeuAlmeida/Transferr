import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/client.dart';

class ClientRepository {
  // O nome da coleção, centralizado e seguro.
  static const String _collectionName = 'clients';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter para a coleção, que usa a constante.
  // Todos os métodos devem usar este getter.
  CollectionReference<Map<String, dynamic>> get _clientsCollection =>
      _firestore.collection(_collectionName);

  /// Retorna uma stream com todos os clientes.
  Stream<List<Client>> getClientsStream() {
    // Este método já estava correto.
    return _clientsCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Client.fromFirestore(doc as DocumentSnapshot<Map<String, dynamic>>);
      }).toList();
    });
  }

  /// Adiciona um novo cliente ao Firestore.
  Future<void> addClient(Client client) {
    // CORREÇÃO: Agora usa o getter _clientsCollection e o método toJson().
    return _clientsCollection.add(client.toMap());
  }

  /// Atualiza um cliente existente.
  Future<void> updateClient(Client client) {
    // CORREÇÃO: Agora usa o getter _clientsCollection e o método toJson().
    return _clientsCollection.doc(client.id).update(client.toMap());
  }

  /// Deleta um cliente.
  Future<void> deleteClient(String clientId) {
    // CORREÇÃO: Também deve usar o getter para consistência.
    return _clientsCollection.doc(clientId).delete();
  }
}
