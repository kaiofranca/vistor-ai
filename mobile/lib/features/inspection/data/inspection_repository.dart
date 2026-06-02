import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:vistor_ai_mobile/core/api/api_client.dart';
import 'package:vistor_ai_mobile/core/api/endpoints.dart';
import 'package:vistor_ai_mobile/core/local/database.dart';
import 'package:vistor_ai_mobile/core/local/inspection_dao.dart';
import 'package:vistor_ai_mobile/shared/models/inspection.dart';

class InspectionRepository {
  final ApiClient _apiClient;
  final InspectionDao _inspectionDao;

  InspectionRepository({
    required ApiClient apiClient,
    required InspectionDao inspectionDao,
  })  : _apiClient = apiClient,
        _inspectionDao = inspectionDao;

  Future<List<Inspection>> getAll({String? status, String? cursor}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null) queryParams['status'] = status;
      if (cursor != null) queryParams['cursor'] = cursor;

      final response = await _apiClient.dio.get(
        AppEndpoints.inspections,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Inspection.fromJson(json)).toList();
      }
      throw Exception('Erro ao buscar inspeções');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {

        final localData = await _inspectionDao.getAllLocal();
        return localData.map((local) => _mapLocalToInspection(local)).toList();
      }
      rethrow;
    }
  }

  Future<Inspection> create(InspectionCreate payload, {required String inspectorId}) async {
    try {
      final response = await _apiClient.dio.post(
        AppEndpoints.inspections,
        data: payload.toJson(),
      );

      if (response.statusCode == 201) {
        return Inspection.fromJson(response.data);
      }
      throw Exception('Erro ao criar inspeção');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {

        final localId = await _inspectionDao.insertLocalInspection(
          LocalInspectionsCompanion.insert(
            inspectorId: inspectorId,
            category: payload.category,
            description: Value(payload.description),
            lat: payload.lat,
            lon: payload.lon,
            gpsAccuracy: Value(payload.gpsAccuracy),
            createdAt: DateTime.now(),
            isSynced: const Value(false),
            status: const Value('draft'),
          ),
        );

        return Inspection(
          id: 'local_$localId',
          inspectorId: inspectorId,
          category: payload.category,
          description: payload.description,
          lat: payload.lat,
          lon: payload.lon,
          gpsAccuracy: payload.gpsAccuracy,
          status: InspectionStatus.draft,
          isSynced: false,
          createdAt: DateTime.now(),
        );
      }
      rethrow;
    }
  }

  // Mapeamento auxiliar...

  Inspection _mapLocalToInspection(dynamic local) {
    return Inspection(
      id: local.remoteId ?? 'local_${local.id}',
      inspectorId: local.inspectorId,
      category: local.category,
      description: local.description,
      lat: local.lat,
      lon: local.lon,
      gpsAccuracy: local.gpsAccuracy,
      status: _mapStatus(local.status),
      severity: _mapSeverity(local.severity),
      isSynced: local.isSynced,
      createdAt: local.createdAt,
    );
  }

  InspectionStatus _mapStatus(String status) {
    return InspectionStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => InspectionStatus.draft,
    );
  }

  InspectionSeverity? _mapSeverity(String? severity) {
    if (severity == null) return null;
    return InspectionSeverity.values.firstWhere(
      (e) => e.name == severity,
      orElse: () => InspectionSeverity.pendingReview,
    );
  }
}
