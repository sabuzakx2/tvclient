import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static FavoritesService? _instance;
  static FavoritesService get instance => _instance ??= FavoritesService._();
  FavoritesService._();

  Set<String> _favorites = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    _favorites = (prefs.getStringList('favorites') ?? []).toSet();
    _loaded = true;
  }

  Future<void> toggle(String channelUuid) async {
    await load();
    if (_favorites.contains(channelUuid)) {
      _favorites.remove(channelUuid);
    } else {
      _favorites.add(channelUuid);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('favorites', _favorites.toList());
  }

  Future<bool> isFavorite(String channelUuid) async {
    await load();
    return _favorites.contains(channelUuid);
  }

  Set<String> get favorites => _favorites;

  Future<void> reload() async {
    _loaded = false;
    await load();
  }
}
