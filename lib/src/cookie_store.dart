/// Stores affinity cookies between ACP transport requests.
abstract interface class AcpCookieStore {
  void store(Iterable<String> setCookieHeaders);
  String? get cookieHeader;
  void clear();
}

/// In-memory ACP affinity cookie store.
class MemoryAcpCookieStore implements AcpCookieStore {
  final Map<String, String> _cookies = {};

  @override
  void store(Iterable<String> setCookieHeaders) {
    for (final header in setCookieHeaders) {
      final pair = header.split(';').first;
      final separator = pair.indexOf('=');
      if (separator > 0) {
        final name = pair.substring(0, separator).trim();
        final value = pair.substring(separator + 1).trim();
        if (name.isNotEmpty) _cookies[name] = value;
      }
    }
  }

  @override
  String? get cookieHeader => _cookies.isEmpty
      ? null
      : _cookies.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join('; ');

  @override
  void clear() => _cookies.clear();
}
