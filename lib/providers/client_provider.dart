import 'dart:async';
import 'package:flutter/material.dart';
import 'package:transferr/providers/excursion_provider.dart';
import '../models/client.dart';
import '../repositories/client_repository.dart';

class ClientProvider with ChangeNotifier {
  final ClientRepository _repository;
  final ExcursionProvider? _excursionProvider;
  StreamSubscription? _clientSubscription;

  List<Client> _allClients = [];
  bool _isLoading = true;
  String? _error;
  String _searchTerm = '';

  List<Client> get clients {
    if (_searchTerm.isEmpty) {
      return _allClients;
    } else {
      return _allClients.where((client) {
        final searchTermLower = _searchTerm.toLowerCase();
        final nameLower = client.name.toLowerCase();
        final cpfUnmasked = client.cpf.replaceAll(RegExp(r'\D'), '');
        final contactUnmasked = client.contact.replaceAll(RegExp(r'\D'), '');

        return nameLower.contains(searchTermLower) ||
            cpfUnmasked.contains(searchTermLower) ||
            contactUnmasked.contains(searchTermLower);
      }).toList();
    }
  }

  bool get isLoading => _isLoading;
  String? get error => _error;
  int get filteredClientsCount => clients.length;

  ClientProvider({
    ClientRepository? repository,
    ExcursionProvider? excursionProvider,
  })  : _repository = repository ?? ClientRepository(),
        _excursionProvider = excursionProvider {
    _listenToClients();
  }

  void searchClients(String term) {
    _searchTerm = term;
    notifyListeners();
  }

  void _listenToClients() {
    print('[ClientProvider] Iniciando escuta da stream de clientes...');
    _clientSubscription?.cancel();
    _clientSubscription = _repository.getClientsStream().listen(
          (clientsList) {
        print('[ClientProvider] Dados recebidos! Quantidade: ${clientsList.length}');

        // 1. CORREÇÃO: Chame _updateClientStatus AQUI, depois de receber a lista.
        _updateClientStatus(clientsList);
      },
      onError: (error) {
        print('[ClientProvider] ERRO CRÍTICO na stream de clientes: $error');
        _isLoading = false;
        _error = 'Falha ao carregar clientes.';
        notifyListeners();
      },
    );
  }

  void _updateClientStatus(List<Client> rawClientsList) {
    // Se o provider de excursão ainda não estiver pronto, apenas carrega os clientes
    if (_excursionProvider == null) {
      _allClients = rawClientsList;
      _isLoading = false;
      notifyListeners();
      return;
    }

    // Pega todos os IDs de passageiros de todas as excursões
    final Set<String> allPassengerIds = {};
    for (var excursion in _excursionProvider!.excursions) {
      // 2. CORREÇÃO: Troque 'participants' por 'passengers' (ou o nome correto no seu modelo Excursion)
      for (var passenger in excursion.participants) {
        allPassengerIds.add(passenger.clientId);
      }
    }

    // Cria a nova lista de clientes, atualizando o status de cada um
    final List<Client> updatedClients = rawClientsList.map((client) {
      final bool isActive = allPassengerIds.contains(client.id);
      return client.copyWith(isActive: isActive); // Usa o copyWith
    }).toList();

    updatedClients.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

    _allClients = updatedClients;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  // ... restante do seu código (getClientById, addClient, etc.) ...

  Client? getClientById(String clientId) {
    try {
      return _allClients.firstWhere((client) => client.id == clientId);
    } catch (e) {
      return null;
    }
  }

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

  @override
  void dispose() {
    print('[ClientProvider] Dispose chamado. Cancelando a inscrição da stream.');
    _clientSubscription?.cancel();
    super.dispose();
  }
}
