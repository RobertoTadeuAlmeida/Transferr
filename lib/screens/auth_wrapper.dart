import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:transferr/screens/home_page.dart';
import 'package:transferr/screens/login_page.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // O StreamBuilder escuta em tempo real as mudanças no estado de autenticação do Firebase
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Enquanto o Firebase está checando se existe um usuário logado,
        // mostramos uma tela de carregamento.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // 2. Se o "snapshot" (o resultado da verificação) tiver dados,
        // significa que o usuário ESTÁ LOGADO. Então, mostramos a HomePage.
        if (snapshot.hasData) {
          return const HomePage();
        }

        // 3. Se o snapshot não tiver dados, o usuário NÃO ESTÁ LOGADO.
        // Então, mostramos a LoginPage.
        return const LoginPage();
      },
    );
  }
}
