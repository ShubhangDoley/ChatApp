import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/user_repository.dart';
import 'search_event.dart';
import 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {
  SearchBloc({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  }) : _authRepository = authRepository,
       _userRepository = userRepository,
       super(const SearchState()) {
    on<SearchQueryChanged>(_onQueryChanged);
    on<SearchCleared>(_onCleared);
  }

  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  Future<void> _onQueryChanged(
    SearchQueryChanged event,
    Emitter<SearchState> emit,
  ) async {
    final query = event.query.trim();
    if (query.isEmpty) {
      emit(
        state.copyWith(
          query: '',
          isLoading: false,
          results: const [],
          errorMessage: null,
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        query: query,
        isLoading: true,
        errorMessage: null,
      ),
    );
    try {
      final currentUser = _authRepository.currentUser;
      final users = await _userRepository.searchUsersByEmail(
        email: query,
        excludeUid: currentUser?.uid,
      );
      emit(
        state.copyWith(
          query: query,
          isLoading: false,
          results: users,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          query: query,
          isLoading: false,
          results: const [],
          errorMessage: error.toString(),
        ),
      );
    }
  }

  void _onCleared(SearchCleared event, Emitter<SearchState> emit) {
    emit(const SearchState());
  }
}
