class UserModel {
  final String nama;
  final String email;

  UserModel({
    required this.nama,
    required this.email,
  });

  // Fungsi dummy (Nanti diganti parsing dari JSON Backend Flask)
  factory UserModel.dummy() {
    return UserModel(
      nama: 'Customer 1',
      email: 'customer1@gmail.com',
    );
  }
}
