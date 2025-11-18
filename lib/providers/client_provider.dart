// lib/providers/client_provider.dart
import 'dart:async';
import 'package:flutter/material.dart';

// 1. Importe o modelo e o repositório de clientes
import '../models/client.dart';
import '../repositories/client_repository.dart';

// 2. A classe ClientProvider, que gerenciará o estado dos clientes.
class ClientProvider with ChangeNotifier {
  // 3. Dependência do repositório, que é a ponte com o Firestore.
  final ClientRepository _repository = ClientRepository();
  StreamSubscription? _clientSubscription;

  // 4. O estado interno do provider.
  List<Client> _clients = [];
  bool _isLoading = true;

  // 5. Getters públicos para a UI acessar o estado de forma segura.
  List<Client> get clients => _clients;
  bool get isLoading => _isLoading;

  // Construtor: assim que o provider é criado, ele começa a ouvir os dados.
  ClientProvider() {
    _listenToClients();
  }

  /// Inicia a "escuta" da stream de clientes do repositório.
  void _listenToClients() {
    print('[ClientProvider] Iniciando escuta da stream de clientes...');
    _clientSubscription = _repository.getClientsStream().listen(
          (clientsList) {
        print('[ClientProvider] Dados de clientes recebidos! Quantidade: ${clientsList.length}');
        _clients = clientsList;
        _isLoading = false;
        notifyListeners(); // Notifica a UI que a lista foi atualizada e o loading acabou.
      },
      onError: (error) {
        print('[ClientProvider] ERRO CRÍTICO na stream de clientes: $error');
        _isLoading = false;
        notifyListeners(); // Notifica a UI sobre o erro para parar o loading.
      },
    );
  }

  // 6. Método utilitário crucial para a tela de detalhes.
  /// Busca um cliente na lista em memória pelo seu ID.
  Client? getClientById(String clientId) {
    try {
      // Usa firstWhere para encontrar o primeiro cliente que corresponde ao ID.
      return _clients.firstWhere((client) => client.id == clientId);
    } catch (e) {
      // Se firstWhere não encontra ninguém, ele lança uma exceção.
      // Capturamos e retornamos null para indicar que o cliente não foi encontrado.
      return null;
    }
  }

  // 7. Métodos CRUD para manipulação de dados.
  Future<void> addClient(Client newClient) async {
    try {
      await _repository.addClient(newClient);
    } catch (e) {
      print('Erro ao adicionar cliente: $e');
      rethrow;
    }
  }

  Future<void> updateClient(Client updatedClient) async {
    try {
      await _repository.updateClient(updatedClient);
    } catch (e) {
      print('Erro ao atualizar cliente: $e');
      rethrow;
    }
  }

  Future<void> deleteClient(String clientId) async {
    try {
      await _repository.deleteClient(clientId);
    } catch (e) {
      print('Erro ao deletar cliente: $e');
      rethrow;
    }
  }

  // 8. Limpeza: cancela a stream para evitar vazamentos de memória (memory leaks).
  @override
  void dispose() {
    print('[ClientProvider] Dispose chamado. Cancelando a inscrição da stream.');
    _clientSubscription?.cancel();
    super.dispose();
  }
}
