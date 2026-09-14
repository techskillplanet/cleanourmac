String shellQuote(String value) => "'${value.replaceAll("'", "'\\''")}'";

String appleScriptStringLiteral(String value) {
  final escaped = value
      .replaceAll(r'\', r'\\')
      .replaceAll('"', r'\"')
      .replaceAll('\n', r'\n');
  return '"$escaped"';
}
