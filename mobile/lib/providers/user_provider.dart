import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

// StateNotifier untuk mengelola state profil pengguna
class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  UserNotifier() : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  // Fungsi pura-pura mengambil data dari API
  Future<void> _loadProfile() async {
    try {
      state = const AsyncValue.loading();
      await Future.delayed(const Duration(seconds: 1)); // Simulasi delay jaringan
      state = AsyncValue.data(UserModel.dummy());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // Logika Keluar Akun (Logout)
  Future<void> logout() async {
    try {
      // 1. Hapus kredensial JWT Token dari brankas lokal
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      
      // 2. Kosongkan state pengguna
      state = const AsyncValue.data(null);
      
    } catch (e) {
       print("Gagal logout: $e");
    }
  }
}

// Provider yang akan dipanggil oleh UI
final userProvider = StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier();
});