import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../generated/locales.g.dart';
import '../../../infrastructure/utils/validators.dart' as validators;
import '../repositories/login_repository.dart';
import '../../../infrastructure/routes/route_names.dart';
import '../../../infrastructure/commons/local_storage_keys.dart';
import '../../../infrastructure/commons/role.dart';

class LoginController extends GetxController {
  final LoginRepository _repository = LoginRepository();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  RxBool isLoading = false.obs;
  RxBool isPasswordVisible = true.obs;
  RxBool rememberMe = false.obs;

  void changeRemember(bool? val) {
    rememberMe.value = !rememberMe.value;
  }

  void togglePassword() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  String? validatePassword(String? value) {
    return validators.validatePasswordCommon(value);
  }

  String? validateUsername(String? value) {
    return validators.validateUsername(value);
  }

  Future<void> login() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    isLoading.value = true;
    final result = await _repository.login(
      username: usernameController.text.toLowerCase(),
      password: passwordController.text,
    );
    result.fold(
      (exception) {
        isLoading.value = false;
        Get.showSnackbar(
          GetSnackBar(
            messageText: Text(
              exception,
              style: const TextStyle(color: Colors.black, fontSize: 14),
            ),
            backgroundColor: Colors.redAccent.withValues(alpha: .2),
            duration: const Duration(seconds: 5),
          ),
        );
      },
      (response) async {
        isLoading.value = false;
        GetStorage storage = GetStorage();
        if (rememberMe.value) {
          storage.write(LocalStorageKeys.rememberMe, true);
        }

        storage.write(LocalStorageKeys.role, roleToString(parseRole(response['role'])));
        storage.write(LocalStorageKeys.userId, response['id']);
        Get.toNamed(RouteNames.missions);
      },
    );
  }

  Future<void> toRegister() async {
    final result = await Get.toNamed(RouteNames.register);
    if (result != null) {
      usernameController.text = result["username"];
      passwordController.text = result["password"];
      Get.showSnackbar(
        GetSnackBar(
          messageText: Text(
            LocaleKeys.login_page_create_user.tr,
            style: const TextStyle(color: Colors.black, fontSize: 14),
          ),
          backgroundColor: Colors.green.withValues(alpha: .2),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    super.dispose();
    passwordController.dispose();
    usernameController.dispose();
  }
}


