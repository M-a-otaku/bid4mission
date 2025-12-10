import 'dart:convert';
import 'package:either_dart/either.dart';
import 'package:get/Get.dart';
import 'package:http/http.dart' as http;
import '../../../../generated/locales.g.dart';
import '../../../infrastructure/commons/url_repository.dart';
import '../models/register_dto.dart';

class RegisterRepository {
  Future<Either<String, Map<String, dynamic>>> register(RegisterDto dto) async {
    try {
      final url = UrlRepository.register;

      final http.Response check = await http.get(url);
      final List<dynamic> checkResponse = json.decode(check.body);
      if (checkResponse.any((user) => user["username"] == dto.username)) {
        return Left(LocaleKeys.error_repository_register_user_exist.tr);
      }

      final Map<String, dynamic> body = dto.toJson();
      final http.Response response = await http.post(url, body: json.encode(body));

      if (response.statusCode != 201) {
        return Left(LocaleKeys.error_repository_login_no_user.tr);
      }

      final Map<String, dynamic> result = json.decode(response.body);
      return Right(result);
    } catch (e) {
      return Left("${LocaleKeys.error_error.tr} ${e.toString()}");
    }
  }
}