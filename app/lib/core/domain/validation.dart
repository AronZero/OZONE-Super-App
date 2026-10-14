/// The result of checking user input: either a usable value or a reason in words
/// (docs/spec/F3-01 §5). Reasons are shown to the user as written.
sealed class Validation<T> {
  const Validation();

  bool get isOk => this is Ok<T>;

  /// The value, or null when invalid.
  T? get valueOrNull => switch (this) {
        Ok<T>(:final value) => value,
        Invalid<T>() => null,
      };
}

final class Ok<T> extends Validation<T> {
  const Ok(this.value);
  final T value;
}

final class Invalid<T> extends Validation<T> {
  const Invalid(this.reason);
  final String reason;
}
