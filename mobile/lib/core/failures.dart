/// Failure domain: representasi kegagalan yang ramah UI.
///
/// Murni Dart (tanpa Flutter/Dio) sehingga bisa dipakai di semua layer.
/// Repository mengembalikan Failure sebagai NILAI (via record), bukan
/// melempar exception mentah ke presentation.
sealed class Failure {
  const Failure(this.message);

  /// Pesan yang aman ditampilkan ke pengguna.
  final String message;
}

/// Kegagalan sumber data lokal (SharedPreferences, storage, cache).
class LocalFailure extends Failure {
  const LocalFailure(super.message);
}

/// Kegagalan jaringan / server cloud.
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
