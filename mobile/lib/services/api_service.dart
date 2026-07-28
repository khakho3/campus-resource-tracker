import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/api_config.dart';
import '../models/library_status.dart';

abstract class LibraryApi {
  Future<LibraryStatus> fetchStatus();

  Future<void> updateLibraryState({bool? isOpen, bool? motionDetected});

  Future<void> updateSeat({required int seatId, required bool isOccupied});

  Future<void> scanStaff(String rfidUid);

  Future<void> resetDemo();
}

class HttpLibraryApi implements LibraryApi {
  HttpLibraryApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 10);

  @override
  Future<LibraryStatus> fetchStatus() async {
    final json = await _request('GET', '${ApiConfig.apiV1}/library/status');
    return LibraryStatus.fromJson(json as Map<String, dynamic>);
  }

  @override
  Future<void> updateLibraryState({bool? isOpen, bool? motionDetected}) async {
    final body = <String, dynamic>{};
    if (isOpen != null) {
      body['is_open'] = isOpen;
    }
    if (motionDetected != null) {
      body['motion_detected'] = motionDetected;
    }
    await _request('PATCH', '${ApiConfig.apiV1}/library/state', body: body);
  }

  @override
  Future<void> updateSeat({
    required int seatId,
    required bool isOccupied,
  }) async {
    await _request(
      'PATCH',
      '${ApiConfig.apiV1}/seats/$seatId',
      body: {'is_occupied': isOccupied},
    );
  }

  @override
  Future<void> scanStaff(String rfidUid) async {
    await _request(
      'POST',
      '${ApiConfig.apiV1}/staff/scan',
      body: {'rfid_uid': rfidUid},
    );
  }

  @override
  Future<void> resetDemo() async {
    await _request('POST', '${ApiConfig.apiV1}/demo/reset');
  }

  Future<dynamic> _request(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final uri = Uri.parse(url);
      final headers = {'Content-Type': 'application/json'};
      late final http.Response response;
      switch (method) {
        case 'GET':
          response = await _client.get(uri, headers: headers).timeout(_timeout);
        case 'POST':
          response = await _client
              .post(
                uri,
                headers: headers,
                body: body == null ? null : jsonEncode(body),
              )
              .timeout(_timeout);
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: jsonEncode(body))
              .timeout(_timeout);
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      final decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message =
            decoded is Map<String, dynamic> && decoded['detail'] is String
            ? decoded['detail'] as String
            : 'Request failed with status ${response.statusCode}.';
        throw ApiException(message);
      }
      return decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('The server took too long to respond.');
    } on FormatException {
      throw const ApiException('The server returned an invalid response.');
    } on http.ClientException {
      throw const ApiException('Could not connect to the library server.');
    } catch (error) {
      throw ApiException('Could not reach the library server: $error');
    }
  }
}

class ApiException implements Exception {
  const ApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
