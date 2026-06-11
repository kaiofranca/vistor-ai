import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:vistor_ai_mobile/shared/models/inspection.dart';

part 'inspection_state.freezed.dart';

@freezed
class InspectionState with _$InspectionState {
  const factory InspectionState.initial() = _Initial;
  const factory InspectionState.loading() = _Loading;
  const factory InspectionState.loaded(List<Inspection> inspections) = _Loaded;
  const factory InspectionState.empty() = _Empty;
  const factory InspectionState.error(String message) = _Error;
}
