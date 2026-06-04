import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vistor_ai_mobile/features/inspection/data/inspection_repository.dart';
import 'package:vistor_ai_mobile/features/inspection/domain/inspection_state.dart';

class InspectionCubit extends Cubit<InspectionState> {
  final InspectionRepository _repository;
  String? _currentStatus;

  InspectionCubit({
    required InspectionRepository repository,
  })  : _repository = repository,
        super(const InspectionState.initial());

  Future<void> load() async {
    emit(const InspectionState.loading());
    try {
      final inspections = await _repository.getAll(status: _currentStatus);
      if (inspections.isEmpty) {
        emit(const InspectionState.empty());
      } else {
        emit(InspectionState.loaded(inspections));
      }
    } catch (e) {
      emit(InspectionState.error(e.toString()));
    }
  }

  Future<void> refresh() async {
    await load();
  }

  void filterByStatus(String? status) {
    _currentStatus = status;
    load();
  }
}
