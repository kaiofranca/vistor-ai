import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GpsPermissionDeniedException implements Exception {
  final String message;
  GpsPermissionDeniedException([this.message = 'Permissão de GPS negada']);
}

class GpsTimeoutException implements Exception {
  final String message;
  GpsTimeoutException([this.message = 'Tempo limite de GPS excedido']);
}

class GpsService {
  Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw GpsPermissionDeniedException('O serviço de localização está desativado');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw GpsPermissionDeniedException();
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw GpsPermissionDeniedException('Permissão de GPS negada permanentemente');
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
    } on TimeoutException {
      throw GpsTimeoutException();
    }
  }

  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

  bool isPrecisionAcceptable(Position p) {
    return p.accuracy <= 50.0;
  }
}
