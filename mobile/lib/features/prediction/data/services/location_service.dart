import 'package:geolocator/geolocator.dart';

/// Pembungkus tipis Geolocator agar presentation tidak menyentuh plugin
/// langsung (mudah di-fake saat testing).
class LocationService {
  /// Ambil posisi GPS terkini. Mengembalikan null bila izin ditolak,
  /// layanan lokasi mati, atau terjadi error — pemanggil memutuskan fallback.
  Future<({double lat, double lng})?> currentPosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low, // cukup untuk level kab/kota
          timeLimit: Duration(seconds: 10),
        ),
      );
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
