import 'package:supabase_flutter/supabase_flutter.dart';

const SUPABASE_URL = 'https://hiuiqbsaqexyyyasabqo.supabase.co';
const SUPABASE_ANON_KEY =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpdWlxYnNhcWV4eXl5YXNhYnFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODQ1MDAyNzEsImV4cCI6MjAwMDA3NjI3MX0.CgGzYPYvrU0EtnZPl83mBR8zL57mIBdXMCFxAfIBI2Y';
final db = Supabase.instance.client;

class DatabaseConnection {
  static initialize() async {
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
    );
  }
}
