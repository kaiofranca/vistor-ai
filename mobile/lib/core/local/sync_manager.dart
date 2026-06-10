import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:vistor_ai_mobile/core/api/api_client.dart';
import 'package:vistor_ai_mobile/core/api/endpoints.dart';
import 'package:vistor_ai_mobile/core/local/inspection_dao.dart';

class SyncManager {
  final ApiClient _apiClient;
  final InspectionDao _inspectionDao;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;
  
  // Callback opcional para notificar a UI sobre o progresso
  void Function(int count)? onSyncSuccess;

  SyncManager(this._apiClient, this._inspectionDao);

  Stream<int> get pendingCount => _inspectionDao.watchPendingCount();
  Stream<int> get pendingCountStream => pendingCount;

  void startListening() {
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none) {
        syncAll();
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }

  Future<void> syncAll() async {
    final pending = await _inspectionDao.getPendingInspections();
    if (pending.isEmpty) return;

    int successCount = 0;
    for (final insp in pending) {
      try {
        final response = await _apiClient.dio.post(
          AppEndpoints.inspections,
          data: {
            'title': insp.title,
            'category': insp.category,
            'description': insp.description,
            'lat': insp.lat,
            'lon': insp.lon,
            'gps_accuracy': insp.gpsAccuracy,
            'address': insp.address,
          },
        );

        if (response.statusCode == 201) {
          final remoteId = response.data['id'];
          await _inspectionDao.markAsSynced(insp.id, remoteId);
          successCount++;
        }
      } catch (e) {
        // Falha silenciosa para manter na fila
        continue;
      }
    }

    if (successCount > 0 && onSyncSuccess != null) {
      onSyncSuccess!(successCount);
    }
  }
}
