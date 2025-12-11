import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../generated/locales.g.dart';
import '../../../infrastructure/commons/role.dart';
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [colorScheme.primary, colorScheme.surface],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
                horizontal: size.width * 0.08, vertical: 20),
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.06),
                  Hero(
                    tag: 'register_icon',
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: Icon(Icons.person_add_rounded,
                          size: 60, color: colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(LocaleKeys.register_page_welcome.tr,
                      style: TextStyle(
                          fontSize: isTablet ? 36 : 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary)),
                  const SizedBox(height: 8),
                  Text(LocaleKeys.register_page_information.tr,
                      style: TextStyle(
                          fontSize: isTablet ? 18 : 16,
                          color: colorScheme.onPrimary.withAlpha(180))),
                  SizedBox(height: size.height * 0.06),
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 36 : 24),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 30,
                            offset: const Offset(0, 10))
                      ],
                    ),
                    child: Column(
                      children: [
                        _textField(
                          context,
                          controller: controller.firstnameController,
                          label: LocaleKeys.register_page_firstname_label.tr,
                          icon: Icons.person,
                          validator: (v) {
                            final base = controller.validateRequired(v);
                            if (base != null) return base;
                            if (controller.firstnameError.value.isNotEmpty)
                              return controller.firstnameError.value;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _textField(
                          context,
                          controller: controller.lastnameController,
                          label: LocaleKeys.register_page_lastname_label.tr,
                          icon: Icons.person,
                          validator: (v) {
                            final base = controller.validateRequired(v);
                            if (base != null) return base;
                            if (controller.lastnameError.value.isNotEmpty)
                              return controller.lastnameError.value;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        _textField(
                          context,
                          controller: controller.usernameController,
                          label: LocaleKeys.login_page_username.tr,
                          icon: Icons.person_outline,
                          validator: (v) {
                            final base = controller.validateUsername(v);
                            if (base != null) return base;
                            if (controller.usernameError.value.isNotEmpty)
                              return controller.usernameError.value;
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Obx(() => _textField(
                              context,
                              controller: controller.passwordController,
                              label: LocaleKeys.login_page_password.tr,
                              icon: Icons.lock_outline,
                              obscureText: controller.isPasswordVisible.value,
                              validator: (v) {
                                final base = controller.validatePassword(v);
                                if (base != null) return base;
                                if (controller.passwordError.value.isNotEmpty)
                                  return controller.passwordError.value;
                                return null;
                              },
                              suffix: IconButton(
                                icon: Icon(
                                    controller.isPasswordVisible.value
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: colorScheme.primary),
                                onPressed: controller.togglePasswordVisibility,
                              ),
                            )),
                        const SizedBox(height: 16),
                        Obx(() => _textField(
                              context,
                              controller: controller.repeatPassController,
                              label:
                                  LocaleKeys.register_page_repeat_password.tr,
                              icon: Icons.lock_outline,
                              obscureText:
                                  controller.isRepeatPasswordVisible.value,
                              validator: controller.validateRepeatPassword,
                              suffix: IconButton(
                                icon: Icon(
                                    controller.isRepeatPasswordVisible.value
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: colorScheme.primary),
                                onPressed:
                                    controller.toggleRepeatPasswordVisibility,
                              ),
                            )),
                        const SizedBox(height: 16),
                        Obx(() => DropdownButtonFormField<Role>(
                              value: controller.selectedRole.value,
                              validator: (value) => value == null
                                  ? LocaleKeys.register_page_role_validator.tr
                                  : null,
                              items: [
                                DropdownMenuItem(
                                    value: Role.employer,
                                    child: Text(LocaleKeys
                                        .register_page_role_employer.tr)),
                                DropdownMenuItem(
                                    value: Role.hunter,
                                    child: Text(LocaleKeys
                                        .register_page_role_hunter.tr)),
                              ],
                              onChanged: (value) {
                                if (value != null)
                                  controller.selectedRole.value = value;
                              },
                              decoration: InputDecoration(
                                labelText:
                                    LocaleKeys.register_page_role_label.tr,
                                prefixIcon: Icon(Icons.work_outline,
                                    color: colorScheme.primary),
                                filled: true,
                                fillColor:
                                    theme.inputDecorationTheme.fillColor ??
                                        theme.cardColor.withValues(alpha: 0.35),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none),
                              ),
                            )),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: Obx(() => ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.doRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  shadowColor:
                                      colorScheme.primary.withAlpha(128),
                                ),
                                child: controller.isLoading.value
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: colorScheme.onPrimary,
                                            strokeWidth: 2.5))
                                    : Text(LocaleKeys.register_page_register.tr,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                              )),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Obx(() => TextButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : Get.back,
                                child: Text(
                                    LocaleKeys.register_page_back_login.tr,
                                    style: TextStyle(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold)))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _textField(BuildContext context,
      {required TextEditingController controller,
      required String label,
      required IconData icon,
      bool obscureText = false,
      String? Function(String?)? validator,
      Widget? suffix}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final fillColor = theme.inputDecorationTheme.fillColor ??
        colorScheme.surfaceContainerLowest.withAlpha(10);

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: validator,
      readOnly: this.controller.isLoading.value,
      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.inputDecorationTheme.labelStyle ??
            TextStyle(color: colorScheme.onSurface),
        prefixIcon: Icon(icon, color: colorScheme.primary),
        suffixIcon: suffix,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.dividerColor)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: colorScheme.primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: theme.disabledColor)),
      ),
    );
  }
}


