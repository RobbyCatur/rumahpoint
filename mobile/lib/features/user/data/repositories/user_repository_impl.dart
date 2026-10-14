import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/failures.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../models/user_model.dart';

/// Implementasi [UserRepository]. Sementara profil masih dummy (backend
/// auth JWT belum jadi), tetapi logout sudah membersihkan kredensial dari
/// secure storage — siap disambungkan ke API backend nanti.
class UserRepositoryImpl implements UserRepository {
  UserRepositoryImpl(this._storage);

  final FlutterSecureStorage _storage;

  @override
  Future<({User? user, Failure? failure})> getProfile() async {
    try {
      // Simulasi delay jaringan; nanti diganti panggilan API backend.
      await Future.delayed(const Duration(seconds: 1));
      return (user: UserModel.dummy(), failure: null);
    } catch (e) {
      return (user: null, failure: LocalFailure('Gagal memuat profil: $e'));
    }
  }

  @override
  Future<Failure?> logout() async {
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      return null;
    } catch (e) {
      return LocalFailure('Gagal logout: $e');
    }
  }
}
