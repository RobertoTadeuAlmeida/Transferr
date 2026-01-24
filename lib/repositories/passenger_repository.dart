import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/passenger.dart';

class PassengerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('passageiros');

  /// 1. CADASTRO GERAL (Sem obrigatoriedade de excursão)
  /// Salva o passageiro na base mestre da empresa
  Future<String> savePassenger(Passenger passenger) async {
    try {
      final docRef = passenger.id.isEmpty
          ? _collection.doc()
          : _collection.doc(passenger.id);

      final data = passenger.toMap();
      data['id'] = docRef.id;
      data['lastUpdate'] = FieldValue.serverTimestamp();

      if (passenger.id.isEmpty) {
        data['createdAt'] = FieldValue.serverTimestamp();
        data['totalViagens'] = 0; // Inicializa contador de fidelidade
      }

      await docRef.set(data, SetOptions(merge: true));
      return docRef.id;
    } catch (e) {
      throw _handleError("salvar cadastro base", e);
    }
  }

  /// 2. REGRA DE NEGÓCIO: VINCULAR A EXCURSÃO COM SINAL
  /// Esta regra agora fica no repositório para garantir integridade
  Future<void> linkToExcursion({
    required String passengerId,
    required String excursionId,
    required double depositValue,
  }) async {
    try {
      // Validação da Regra de Negócio: Exige sinal maior que zero
      if (depositValue <= 0) {
        throw Exception("O pagamento do sinal é obrigatório para vincular à excursão.");
      }

      await _collection.doc(passengerId).update({
        'excursionId': excursionId,
        'depositValue': depositValue,
        'statusViagem': 'confirmada', // Status ativo
        'dataVinculo': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _handleError("vincular passageiro à excursão", e);
    }
  }

  /// 3. BUSCA DE TODOS OS PASSAGEIROS DA EMPRESA (Geral)
  /// Usado na tela principal de passageiros para ver quem tem viagem ativa ou não
  Future<List<Passenger>> getAllPassengers() async {
    try {
      final snapshot = await _collection.orderBy('nome').get();
      return snapshot.docs
          .map((doc) => Passenger.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw _handleError("buscar todos os passageiros", e);
    }
  }

  /// 4. BUSCA POR EXCURSÃO (Filtro específico)
  Stream<List<Passenger>> getPassengersStream(String excursionId) {
    return _collection
        .where('excursionId', isEqualTo: excursionId)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => Passenger.fromMap(doc.id, doc.data()))
        .toList());
  }
  /// Atualiza o status de embarque e registra o agente responsável
  Future<void> updateBoardingStatus({
    required String passengerId,
    required String statusValue,
    required String agenteId,
  }) async {
    try {
      await _collection.doc(passengerId).update({
        'statusEmbarque': statusValue,
        'agenteResponsavel': agenteId,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _handleError("atualizar status de embarque", e);
    }
  }

  /// Busca a lista de passageiros de uma excursão específica (Future)
  Future<List<Passenger>> getPassengers(String excursionId) async {
    try {
      final snapshot = await _collection
          .where('excursionId', isEqualTo: excursionId)
          .get();

      return snapshot.docs
          .map((doc) => Passenger.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      throw _handleError("buscar passageiros da excursão", e);
    }
  }

  /// 5. ATUALIZAR STATUS DE EMBARQUE E CONTADOR DE VIAGENS
  /// Quando o passageiro embarca/finaliza, podemos incrementar o totalViagens
  Future<void> completeTrip(String passengerId) async {
    try {
      await _collection.doc(passengerId).update({
        'totalViagens': FieldValue.increment(1),
        'excursionId': null, // Libera para próxima viagem
        'statusViagem': 'finalizada',
      });
    } catch (e) {
      throw _handleError("finalizar viagem", e);
    }
  }

  // --- Métodos de Apoio Mantidos ---

  Future<void> updatePassengerSeat(String passengerId, String? seatNumber) async {
    try {
      await _collection.doc(passengerId).update({
        'seatNumber': seatNumber,
        'atualizadoEm': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw _handleError("atualizar assento", e);
    }
  }

  Future<void> deletePassenger(String passengerId) async {
    try {
      await _collection.doc(passengerId).delete();
    } catch (e) {
      throw _handleError("remover passageiro", e);
    }
  }

  Exception _handleError(String acao, dynamic e) {
    if (e is FirebaseException && e.code == 'permission-denied') {
      return Exception("Erro de permissão: Verifique as regras ou índices.");
    }
    return Exception("Falha ao $acao: $e");
  }
}