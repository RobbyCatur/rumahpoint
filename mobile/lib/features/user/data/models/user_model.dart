import '../../domain/entities/user.dart';

/// Representasi data pengguna (JSON backend / dummy) + mapping ke entity.
class UserModel extends User {
  const UserModel({
    required super.nama,
    required super.email,
  });

  factory UserModel.fromJson(Map<String, dynamic> j) => UserModel(
        nama: j['nama']?.toString() ?? '',
        email: j['email']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {'nama': nama, 'email': email};

  /// Placeholder sampai backend auth JWT tersambung.
  factory UserModel.dummy() {
    return const UserModel(
      nama: 'Customer 1',
      email: 'customer1@gmail.com',
    );
  }
}
