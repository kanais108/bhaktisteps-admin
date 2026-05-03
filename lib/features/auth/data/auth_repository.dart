import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';

class AuthRepository {
  final ApiClient apiClient;
  final AuthStorage authStorage;

  AuthRepository({required this.apiClient, required this.authStorage});

  Future<void> requestOtp(String email) async {
    await apiClient.dio.post(
      '/auth/request-otp',
      data: {'email': email.trim()},
    );
  }

  Future<void> verifyOtp({required String email, required String otp}) async {
    final response = await apiClient.dio.post(
      '/auth/verify-otp',
      data: {'email': email.trim(), 'otp': otp.trim()},
    );

    final token = response.data['token'] as String?;
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: response.requestOptions,
        error: 'Token missing in response',
      );
    }

    await authStorage.saveToken(token);
  }

  Future<void> logout() async {
    await authStorage.clearToken();
  }

  Future<bool> isLoggedIn() async {
    final token = await authStorage.getToken();
    return token != null && token.isNotEmpty;
  }
}
