import 'package:dartz/dartz.dart';

class Failure {
  final String message;
  const Failure(this.message);
}

extension EitherX<T> on Either<Failure, T> {
  T unwrap() =>
      fold((failure) => throw StateError(failure.message), (value) => value);
}
