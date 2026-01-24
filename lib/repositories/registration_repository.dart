import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import '../models/user.dart';

class RegistrationRepository {
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> signUp({required User user, required String password}) async {
    fb_auth.UserCredential? userCredential;

    try {
      // 1. Criar o usuário no Firebase Auth
      userCredential = await _auth.createUserWithEmailAndPassword(
        email: user.email.trim(),
        password: password.trim(),
      );

      final String uid = userCredential.user!.uid;

      // 2. Preparar os dados do usuário para o Firestore
      // Injetamos o UID no ID e no campo COMPANY para satisfazer as Security Rules
      final userWithId = user.copyWith(
        id: uid,
        company: uid,
      );

      // Converte para Map e remove valores nulos para evitar erros internos do Firebase (Pigeon)
      final Map<String, dynamic> rawData = userWithId.toMap();
      final Map<String, dynamic> cleanData = _filterNullValues(rawData);

      debugPrint("Iniciando gravação no Firestore para o UID: $uid");

      // 3. Salvar na coleção 'usuario' usando o UID como ID do documento
      await _firestore
          .collection('usuario')
          .doc(uid)
          .set(cleanData);

      // 4. Atualizar o Display Name no Firebase Auth (metadados)
      await userCredential.user?.updateDisplayName(user.name);

      debugPrint("Cadastro e perfil criados com sucesso!");

    } on fb_auth.FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } on FirebaseException catch (e) {
      // ROLLBACK: Se o Firestore falhar, removemos o usuário do Auth
      // para não bloquear o e-mail em uma tentativa futura.
      await _rollbackAuth(userCredential);

      debugPrint('Erro Firestore [${e.code}]: ${e.message}');
      throw _handleFirestoreError(e);
    } catch (e) {
      // ROLLBACK para erros genéricos
      await _rollbackAuth(userCredential);

      debugPrint("Erro inesperado no cadastro: $e");
      throw 'Erro inesperado ao processar cadastro. Tente novamente.';
    }
  }

  /// Remove campos nulos do Map para evitar falhas de cast no driver nativo
  Map<String, dynamic> _filterNullValues(Map<String, dynamic> data) {
    final Map<String, dynamic> filtered = {};
    data.forEach((key, value) {
      if (value != null) {
        filtered[key] = value;
      }
    });
    return filtered;
  }

  /// Deleta o usuário do Firebase Auth caso a criação no Firestore falhe
  Future<void> _rollbackAuth(fb_auth.UserCredential? credential) async {
    try {
      if (credential?.user != null) {
        await credential!.user!.delete();
        debugPrint("Rollback: Usuário removido do Auth por erro no banco.");
      }
    } catch (e) {
      debugPrint("Falha no rollback: $e");
    }
  }

  String _handleAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Este e-mail já está sendo usado por outra empresa.';
      case 'invalid-email':
        return 'O formato do e-mail é inválido.';
      case 'weak-password':
        return 'A senha deve ter pelo menos 6 caracteres.';
      case 'network-request-failed':
        return 'Verifique sua conexão com a internet.';
      default:
        return 'Erro na autenticação: ${e.message}';
    }
  }

  String _handleFirestoreError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      return 'Erro de permissão: Verifique as regras de segurança do banco.';
    }
    return 'Erro ao salvar dados: ${e.message}';
  }
}