import 'package:equatable/equatable.dart';

import '../../../data/models/app_user.dart';

class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.isLoading = false,
    this.results = const [],
    this.errorMessage,
  });

  final String query;
  final bool isLoading;
  final List<AppUser> results;
  final String? errorMessage;

  static const _unset = Object();

  SearchState copyWith({
    String? query,
    bool? isLoading,
    List<AppUser>? results,
    Object? errorMessage = _unset,
  }) {
    return SearchState(
      query: query ?? this.query,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }

  @override
  List<Object?> get props => [query, isLoading, results, errorMessage];
}
