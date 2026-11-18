/// Entity bisnis murni untuk pengguna. Tanpa mapping / Flutter.
class User {
  const User({
    required this.nama,
    required this.email,
    this.avatarBase64,
  });

  final String nama;
  final String email;
  final String? avatarBase64;
}
