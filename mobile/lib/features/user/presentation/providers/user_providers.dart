import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/repositories/user_repository_impl.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';

/// Wiring DI untuk fitur user — satu-satunya tempat 'new' implementasi.

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(ref.watch(secureStorageProvider));
});

/// Notifier bergantung pada abstraksi [UserRepository].
class UserNotifier extends StateNotifier<AsyncValue<User?>> {
  UserNotifier(this._repository) : super(const AsyncValue.loading()) {
    _loadProfile();
  }

  final UserRepository _repository;

  Future<void> _loadProfile() async {
    state = const AsyncValue.loading();
    final result = await _repository.getProfile();
    if (result.failure != null) {
      state = AsyncValue.error(result.failure!.message, StackTrace.current);
    } else {
      state = AsyncValue.data(result.user);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }
}

final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<User?>>((ref) {
  return UserNotifier(ref.watch(userRepositoryProvider));
});
