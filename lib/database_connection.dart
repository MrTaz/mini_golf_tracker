import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = 'https://hiuiqbsaqexyyyasabqo.supabase.co';
const supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhpdWlxYnNhcWV4eXl5YXNhYnFvIiwicm9sZSI6ImFub24iLCJpYXQiOjE2ODQ1MDAyNzEsImV4cCI6MjAwMDA3NjI3MX0.CgGzYPYvrU0EtnZPl83mBR8zL57mIBdXMCFxAfIBI2Y';
SupabaseClient get db => DatabaseConnection.client;

class DatabaseConnection {
  static SupabaseClient get client => Supabase.instance.client;

  static initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
