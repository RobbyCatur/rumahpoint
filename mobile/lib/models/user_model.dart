class UserModel {
  final String nama;
  final String email;
  final int totalValuasi;
  final int totalDisimpan;
  final int totalPortofolio;

  UserModel({
    required this.nama,
    required this.email,
    required this.totalValuasi,
    required this.totalDisimpan,
    required this.totalPortofolio,
  });

  // Fungsi dummy (Nanti diganti parsing dari JSON Backend Flask)
  factory UserModel.dummy() {
    return UserModel(
      nama: 'Customer 1',
      email: 'customer1@gmail.com',
      totalValuasi: 48,
      totalDisimpan: 12,
      totalPortofolio: 3,
    );
  }
}