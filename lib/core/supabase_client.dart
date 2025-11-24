import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

const _url = String.fromEnvironment('SUPABASE_URL');
const _anon = String.fromEnvironment('SUPABASE_ANON_KEY');

SupabaseClient? _client;

Future<void> initSupabase() async {
  if (_client != null) return;
  final url = dotenv.env['SUPABASE_URL'] ?? _url;
  final anon = dotenv.env['SUPABASE_ANON_KEY'] ?? _anon;
  await Supabase.initialize(url: url, anonKey: anon);
  _client = Supabase.instance.client;
}

SupabaseClient get supabase => _client!;

