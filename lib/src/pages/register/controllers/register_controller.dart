import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import 'package:get_storage/get_storage.dart';
import '../../../../generated/locales.g.dart';
import '../../../infrastructure/commons/local_storage_keys.dart';
import '../../../infrastructure/commons/role.dart';
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

  RxBool isLoading = false.obs;
  RxBool isPasswordVisible = true.obs;
  RxBool isRepeatPasswordVisible = true.obs;
  Rx<Role> selectedRole = Rx<Role>(Role.hunter);
  // per-field server/other errors (displayed inline via validators)
  RxString usernameError = ''.obs;
  RxString firstnameError = ''.obs;
  RxString lastnameError = ''.obs;
  RxString passwordError = ''.obs;
  RxString repeatPasswordError = ''.obs;

  void onPressed() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void onPressedRepeat() {
    isRepeatPasswordVisible.value = !isRepeatPasswordVisible.value;
  }

  @override
  void onInit() {
    super.onInit();
    // clear field-specific server errors when user edits the corresponding field
    usernameController.addListener(() {
      if (usernameError.value.isNotEmpty) usernameError.value = '';
    });
    firstnameController.addListener(() {
      if (firstnameError.value.isNotEmpty) firstnameError.value = '';
    });
    lastnameController.addListener(() {
      if (lastnameError.value.isNotEmpty) lastnameError.value = '';
    });
    passwordController.addListener(() {
      if (passwordError.value.isNotEmpty) passwordError.value = '';
      // also clear repeat error when password changes
      if (repeatPasswordError.value.isNotEmpty) repeatPasswordError.value = '';
    });
    repeatPassController.addListener(() {
      if (repeatPasswordError.value.isNotEmpty) repeatPasswordError.value = '';
    });
  }

  String? validate(String? value) {
    if (value?.trim().isEmpty ?? true) return LocaleKeys.validate_required.tr;
    return null;
  }

  String? validatePassword(String? value) {
    RegExp regex = RegExp(r'^(?=[a-zA-Z0-9._]{8,20}$)(?!.*[_.]{2})[^_.].*[^_.]$');
    if (value?.trim().isEmpty ?? true) {
      return LocaleKeys.login_page_validate_password.tr;
    } else if (!regex.hasMatch(value!)) {
      return LocaleKeys.login_page_validate_password_min.tr;
    }
    if (passwordError.value.isNotEmpty) return passwordError.value;
    return null;
  }

  String? validateRepeatPassword(String? value) {
    // basic password validation
    final base = validatePassword(value);
    if (base != null) return base;
    // check for equality with password
    if (value != passwordController.text) return LocaleKeys.register_page_password_not_match.tr;
    // also surface any server-set repeat password error
    if (repeatPasswordError.value.isNotEmpty) return repeatPasswordError.value;
    return null;
  }

  String? validateUsername(String? value) {
    if (value?.trim().isEmpty ?? true) {
      return LocaleKeys.login_page_validate_username.tr;
    }
    if (usernameError.value.isNotEmpty) return usernameError.value;
    return null;
  }

  Future<void> doRegister() async {
    if (!(formKey.currentState?.validate() ?? false)) return;
    if (passwordController.text != repeatPassController.text) {
      // set inline error on repeat password and revalidate to show it
      repeatPasswordError.value = LocaleKeys.register_page_password_not_match.tr;
      formKey.currentState?.validate();
      return;
    }
    isLoading.value = true;

    final RegisterDto dto = RegisterDto(
      username: usernameController.text.toLowerCase(),
      firstname: firstnameController.text,
      lastname: lastnameController.text,
      password: passwordController.text,
      role: roleToString(selectedRole.value),
    );

    final result = await _repository.register(dto);

    result.fold(
          (exception) {
        // show server-side error inline when possible. Try to assign to username first
        isLoading.value = false;
        // if server message mentions username, attach to username field, otherwise set as usernameError by default
        final msg = exception.toString();
        usernameError.value = msg;
        // revalidate to display the inline message
        formKey.currentState?.validate();
      },
          (map) {
        isLoading.value = false;
        GetStorage storage = GetStorage();
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
    super.dispose();
    firstnameController.dispose();
    lastnameController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    repeatPassController.dispose();
  }
}