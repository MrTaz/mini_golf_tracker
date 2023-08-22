class DatabaseConnectionError implements Exception {
  DatabaseConnectionError(this.message);

  final String message;
}
