import '../../domain/entities/user.dart';

/// Representasi data pengguna (JSON backend / dummy) + mapping ke entity.
class UserModel extends User {
  const UserModel({
    required super.nama,
    required super.email,
    super.avatarBase64,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        nama: j['nama']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
        avatarBase64: j['avatarBase64']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'nama': nama,
        'email': email,
        'avatarBase64': avatarBase64,
      };

  /// Placeholder sampai backend auth JWT tersambung.
  factory UserModel.dummy() {
    return const UserModel(
      nama: 'Customer 1',
      email: 'customer1@gmail.com',
    );
  }
}
