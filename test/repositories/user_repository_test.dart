import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:transferr/models/user.dart';
import 'package:transferr/repositories/user_repository.dart';

class MockFirebaseAuth extends Mock implements fb_auth.FirebaseAuth {}
class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}
class MockUserCredential extends Mock implements fb_auth.UserCredential {}
class MockfbUser extends Mock implements fb_auth.User {}
class MockQuerySnapshot extends Mock implements QuerySnapshot<Map<String, dynamic>> {}
class MockUserQuerySnapshot extends Mock implements QuerySnapshot<User> {}
class MockDocumentSnapshot extends Mock implements DocumentSnapshot<Map<String, dynamic>> {}
class MockCollectionReference extends Mock implements CollectionReference<Map<String, dynamic>> {}
class MockUserCollectionReference extends Mock implements CollectionReference<User> {}
class MockDocumentReference extends Mock implements DocumentReference<Map<String, dynamic>> {}
class MockUserDocumentReference extends Mock implements DocumentReference<User> {}
class MockQuery extends Mock implements Query<Map<String, dynamic>> {}
class MockUserQuery extends Mock implements Query<User> {}

void main() {
  late UserRepository repository;
  late MockFirebaseAuth mockAuth;
  late MockFirebaseFirestore mockFirestore;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockFirestore = MockFirebaseFirestore();
    repository = UserRepository(auth: mockAuth, firestore: mockFirestore);
  });

  group('UserRepository - Auth', () {
    test('Deve chamar signInWithEmailAndPassword no FirebaseAuth', () async {
      final mockCredential = MockUserCredential();
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => mockCredential);

      await repository.signIn('teste@email.com', '123456');

      verify(() => mockAuth.signInWithEmailAndPassword(
            email: 'teste@email.com',
            password: '123456',
          )).called(1);
    });

    test('Deve deletar o usuário do Auth em caso de erro no registro', () async {
      final mockfbUser = MockfbUser();
      when(() => mockfbUser.delete()).thenAnswer((_) async => {});

      await repository.deleteAuthUser(mockfbUser);

      verify(() => mockfbUser.delete()).called(1);
    });
  });

  group('UserRepository - Multi-tenant & Security Rules', () {
    test('getUserByEmail deve usar limit(1) para conformidade com Security Rules', () async {
      final mockCollection = MockCollectionReference();
      final mockUserCollection = MockUserCollectionReference();
      final mockQuery = MockUserQuery();
      final mockSnapshot = MockUserQuerySnapshot();

      when(() => mockFirestore.collection('usuario')).thenReturn(mockCollection);
      
      // Stub com withConverter para retornar a coleção tipada como User
      when(() => mockCollection.withConverter<User>(
            fromFirestore: any(named: 'fromFirestore'),
            toFirestore: any(named: 'toFirestore'),
          )).thenReturn(mockUserCollection);

      when(() => mockUserCollection.where('email', isEqualTo: any(named: 'isEqualTo')))
          .thenReturn(mockQuery);
      
      when(() => mockQuery.limit(1)).thenReturn(mockQuery);
      when(() => mockQuery.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.docs).thenReturn([]);

      await repository.getUserByEmail('teste@email.com');

      verify(() => mockQuery.limit(1)).called(1);
    });

    test('getUsersStream deve filtrar pela lista de empresas usando arrayContains', () {
      final mockCollection = MockCollectionReference();
      final mockUserCollection = MockUserCollectionReference();
      final mockQuery = MockUserQuery();

      when(() => mockFirestore.collection('usuario')).thenReturn(mockCollection);
      
      when(() => mockCollection.withConverter<User>(
            fromFirestore: any(named: 'fromFirestore'),
            toFirestore: any(named: 'toFirestore'),
          )).thenReturn(mockUserCollection);

      when(() => mockUserCollection.where('empresas', arrayContains: any(named: 'arrayContains')))
          .thenReturn(mockQuery);
      
      when(() => mockQuery.snapshots()).thenAnswer((_) => const Stream.empty());

      repository.getUsersStream('emp_1');

      verify(() => mockUserCollection.where('empresas', arrayContains: 'emp_1')).called(1);
    });

    test('getCompanyName deve retornar o nome da empresa a partir do ID do usuário proprietário', () async {
      final mockCollection = MockCollectionReference();
      final mockDoc = MockDocumentReference();
      final mockSnapshot = MockDocumentSnapshot();

      when(() => mockFirestore.collection('usuario')).thenReturn(mockCollection);
      when(() => mockCollection.doc(any())).thenReturn(mockDoc);
      when(() => mockDoc.get()).thenAnswer((_) async => mockSnapshot);
      when(() => mockSnapshot.exists).thenReturn(true);
      when(() => mockSnapshot.data()).thenReturn({
        'nomeEmpresa': 'Transferr Agência',
        'nome': 'Proprietário João'
      });

      final name = await repository.getCompanyName('u123');

      expect(name, equals('Transferr Agência'));
    });
  });
}
