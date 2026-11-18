import '../../../../core/failures.dart';
import '../entities/user.dart';

/// Kontrak domain untuk data pengguna & sesi.
///
/// Implementasi (secure storage / API backend) ada di data layer. Titik ini
/// yang nanti menjembatani auth JWT backend tanpa mengubah presentation.
abstract class UserRepository {
  /// Ambil profil pengguna yang sedang aktif (null bila belum login).
  Future<({User? user, Failure? failure})> getProfile();

  /// Simpan foto profil lokal dan kembalikan error bila penyimpanan gagal.
  Future<Failure?> updateProfilePhoto(String? avatarBase64);

  /// Hapus sesi/kredensial lokal (logout).
  Future<Failure?> logout();
}
