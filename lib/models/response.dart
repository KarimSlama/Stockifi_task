class Response<T> {
  final String? message;
  final T? data;
  final bool hasError;

  Response({
    this.message,
    this.data,
    this.hasError = false,
  });
}
