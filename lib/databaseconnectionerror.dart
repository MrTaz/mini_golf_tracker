class DatabaseConnectionError implements Exception {
  final String message;

  DatabaseConnectionError(this.message);
}
