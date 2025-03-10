import 'dart:convert';

import 'package:dio/dio.dart';

class JsonPrettyConverter {
  static JsonPrettyConverter? _instance;

  factory JsonPrettyConverter() =>
      _instance ??= JsonPrettyConverter._internal();
  JsonPrettyConverter._internal() {
    _encoder = const JsonEncoder.withIndent('  ');
  }

  static late final JsonEncoder _encoder;

  String convert(text) {
    late final String prettyprint;
    if (text is Map || text is String || text is List)
      prettyprint = _convertToPrettyJsonFromMapOrJson(text);
    else if (text is FormData)
      prettyprint = 'FormData:\n${_convertToPrettyFromFormData(text)}';
    else if (text == null)
      prettyprint = '';
    else
      prettyprint = text.toString();
    return prettyprint;
  }

  String _convertToPrettyFromFormData(FormData text) {
    final map = {
      for (final e in text.fields) e.key: e.value,
      for (final e in text.files) e.key: e.value.filename
    };

    return _convertToPrettyJsonFromMapOrJson(map);
  }

  String _convertToPrettyJsonFromMapOrJson(text) {
    if (text is! Map) return _encoder.convert(text);

    text = {
      for (final e in text.entries)
        if (e.value is Map || e.value is List || e.value is String)
          e.key: e.value
        else
          e.key: convert(e.value)
    };
    return _encoder.convert(text);
  }

  Map<String, dynamic> mapFromString(String text) {
    try {
      return jsonDecode(text);
    } catch (e) {
      return {};
    }
  }
}
