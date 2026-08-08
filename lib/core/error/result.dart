import 'package:equatable/equatable.dart';

import 'failure.dart';

/// Sealed result type returned by every repository method — no cross-layer
/// `throw`. Use the `when`/`isSuccess` helpers instead of pattern matching
/// on subtype when a shorter call site reads better.
sealed class Result<T, F extends Failure> extends Equatable {
  const Result();

  bool get isSuccess => this is Success<T, F>;
  bool get isFailure => this is Error<T, F>;

  R when<R>({
    required R Function(T value) success,
    required R Function(F failure) failure,
  }) {
    final self = this;
    return switch (self) {
      Success<T, F>() => success(self.value),
      Error<T, F>() => failure(self.failure),
    };
  }
}

final class Success<T, F extends Failure> extends Result<T, F> {
  const Success(this.value);

  final T value;

  @override
  List<Object?> get props => [value];
}

final class Error<T, F extends Failure> extends Result<T, F> {
  const Error(this.failure);

  final F failure;

  @override
  List<Object?> get props => [failure];
}
