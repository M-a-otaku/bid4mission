import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../generated/locales.g.dart';
import '../../../infrastructure/commons/local_storage_keys.dart';
import '../../../infrastructure/commons/role.dart';
import '../../../infrastructure/utils/validators.dart' as validators;
import '../models/register_dto.dart';
import '../repositories/register_repository.dart';

class RegisterController extends GetxController {
  final RegisterRepository _repository = RegisterRepository();

  final usernameController = TextEditingController();
  final firstnameController = TextEditingController();
  final lastnameController = TextEditingController();
  final passwordController = TextEditingController();
  final repeatPassController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final RxBool isLoading = false.obs;
  final RxBool isPasswordVisible = true.obs;
  final RxBool isRepeatPasswordVisible = true.obs;
  final Rx<Role> selectedRole = Rx<Role>(Role.hunter);

  final RxString usernameError = ''.obs;
  final RxString firstnameError = ''.obs;
  final RxString lastnameError = ''.obs;
  final RxString passwordError = ''.obs;
  final RxString repeatPasswordError = ''.obs;

  void togglePasswordVisibility() => isPasswordVisible.value = !isPasswordVisible.value;
  void toggleRepeatPasswordVisibility() => isRepeatPasswordVisible.value = !isRepeatPasswordVisible.value;

  String? validateRequired(String? value) {
    if (value?.trim().isEmpty ?? true) return LocaleKeys.validate_required.tr;
    return null;
  }

  String? validatePassword(String? value) => validators.validatePasswordCommon(value, serverError: passwordError.value);

  String? validateRepeatPassword(String? value) {
    final base = validatePassword(value);
    if (base != null) return base;
    if (value != passwordController.text) return LocaleKeys.register_page_password_not_match.tr;
    if (repeatPasswordError.value.isNotEmpty) return repeatPasswordError.value;
    return null;
  }

  String? validateUsername(String? value) {
    final base = validators.validateUsername(value);
    if (base != null) return base;
    if (usernameError.value.isNotEmpty) return usernameError.value;
    return null;
  }

  Future<void> doRegister() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (passwordController.text != repeatPassController.text) {
      repeatPasswordError.value = LocaleKeys.register_page_password_not_match.tr;
      return;
    }

    isLoading.value = true;

    final dto = RegisterDto(
      username: usernameController.text.toLowerCase(),
      firstname: firstnameController.text,
      lastname: lastnameController.text,
      password: passwordController.text,
      role: roleToString(selectedRole.value),
    );

    final result = await _repository.register(dto);

    result.fold(
      (exception) {
        isLoading.value = false;
        usernameError.value = exception.toString();
      },
      (map) {
        isLoading.value = false;
        final storage = GetStorage();
        storage.write(LocalStorageKeys.userId, map['id']);
        storage.write(LocalStorageKeys.role, roleToString(selectedRole.value));
        Get.back(result: {
          'username': usernameController.text,
          'password': passwordController.text,
        });
      },
    );
  }

  @override
  void dispose() {
    firstnameController.dispose();
    lastnameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    repeatPassController.dispose();
    super.dispose();
  }
}

