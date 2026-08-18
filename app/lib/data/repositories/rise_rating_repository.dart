import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/rise_rating.dart';

/// Wraps `public.v_rise_rating` (FR-5.1–5.5) — Current/Potential/Day-1 are
/// all computed server-side and returned in one row per active challenge.
class RiseRatingRepository {
  RiseRatingRepository(this._client);
  final SupabaseClient _client;

  Future<RiseRating?> getRiseRating() async {
    final row = await _client.from('v_rise_rating').select().maybeSingle();
    return row == null ? null : RiseRating.fromJson(row);
  }
}
