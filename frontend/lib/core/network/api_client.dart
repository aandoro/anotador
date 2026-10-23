import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class NetworkException implements Exception {
  final String message;

  NetworkException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client;
  final Duration _timeout;
  String? _authToken;

  ApiClient({
    http.Client? client,
    Duration timeout = const Duration(seconds: 15),
  })  : _client = client ?? http.Client(),
        _timeout = timeout;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  Map<String, String> _buildHeaders(Map<String, String>? extra) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    if (extra != null) {
      headers.addAll(extra);
    }
    return headers;
  }

  Future<dynamic> get(String url, {Map<String, String>? headers}) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .get(uri, headers: _buildHeaders(headers))
          .timeout(_timeout);
      return _processResponse(response);
    } on TimeoutException {
      throw NetworkException('Tiempo de espera agotado al conectar al servidor.');
    } on http.ClientException catch (e) {
      throw NetworkException('Error de red: ${e.message}');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Error de comunicación: $e');
    }
  }

  Future<dynamic> post(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .post(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);
      return _processResponse(response);
    } on TimeoutException {
      throw NetworkException('Tiempo de espera agotado al conectar al servidor.');
    } on http.ClientException catch (e) {
      throw NetworkException('Error de red: ${e.message}');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Error de comunicación: $e');
    }
  }

  Future<dynamic> put(
    String url, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .put(
            uri,
            headers: _buildHeaders(headers),
            body: body != null ? json.encode(body) : null,
          )
          .timeout(_timeout);
      return _processResponse(response);
    } on TimeoutException {
      throw NetworkException('Tiempo de espera agotado al conectar al servidor.');
    } on http.ClientException catch (e) {
      throw NetworkException('Error de red: ${e.message}');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Error de comunicación: $e');
    }
  }

  Future<dynamic> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final response = await _client
          .delete(uri, headers: _buildHeaders(headers))
          .timeout(_timeout);
      return _processResponse(response);
    } on TimeoutException {
      throw NetworkException('Tiempo de espera agotado al conectar al servidor.');
    } on http.ClientException catch (e) {
      throw NetworkException('Error de red: ${e.message}');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Error de comunicación: $e');
    }
  }

  Future<dynamic> postMultipartBytes({
    required String url,
    required List<int> bytes,
    required String filename,
    String fieldName = 'file',
    Map<String, String>? headers,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      if (_authToken != null && _authToken!.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $_authToken';
      }
      if (headers != null) {
        request.headers.addAll(headers);
      }

      final ext = filename.split('.').last.toLowerCase();
      MediaType? mediaType;
      if (ext == 'jpg' || ext == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (ext == 'webp') {
        mediaType = MediaType('image', 'webp');
      }

      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: mediaType,
      ));

      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);
      return _processResponse(response);
    } on TimeoutException {
      throw NetworkException('Tiempo de espera agotado al subir el archivo.');
    } on http.ClientException catch (e) {
      throw NetworkException('Error de red al subir archivo: ${e.message}');
    } catch (e) {
      if (e is ApiException || e is NetworkException) rethrow;
      throw NetworkException('Error subiendo archivo: $e');
    }
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = json.decode(utf8.decode(response.bodyBytes));
    } catch (_) {
      body = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      String message = 'Error en la petición (${response.statusCode})';
      if (body is Map<String, dynamic>) {
        if (body['detail'] != null) {
          message = body['detail'].toString();
        } else if (body['message'] != null) {
          message = body['message'].toString();
        }
      }
      throw ApiException(message, statusCode: response.statusCode);
    }
  }

  void close() {
    _client.close();
  }
}