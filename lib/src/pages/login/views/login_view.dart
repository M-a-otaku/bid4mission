import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../generated/locales.g.dart';
import '../controller/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

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
            colors: [
              colorScheme.primary,
              colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.08,
              vertical: 20,
            ),
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.08),

                  Hero(
                    tag: "login_icon",
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
                      child: Icon(Icons.person_rounded,
                          size: 60, color: colorScheme.primary),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    LocaleKeys.login_page_welcome.tr,
                    style: TextStyle(
                        fontSize: isTablet ? 36 : 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary),
                  ),

                  Text(
                    LocaleKeys.login_page_sign_in.tr,
                    style: TextStyle(
                        fontSize: isTablet ? 20 : 18, color: colorScheme.onPrimary.withValues(alpha: 180/255)),
                  ),

                  SizedBox(height: size.height * 0.08),

                  // کارت فرم
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(isTablet ? 40 : 28),
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black12,
                            blurRadius: 30,
                            offset: const Offset(0, 10)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTextFormField(
                          context,
                          textController: controller.usernameController,
                          label: LocaleKeys.login_page_username.tr,
                          icon: Icons.person_outline,
                          validator: controller.validateUsername,
                        ),

                        const SizedBox(height: 20),

                        Obx(() => _buildTextFormField(
                              context,
                              textController: controller.passwordController,
                              label: LocaleKeys.login_page_password.tr,
                              icon: Icons.lock_outline,
                              obscureText: controller.isPasswordVisible.value,
                              validator: controller.validatePassword,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.isPasswordVisible.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: colorScheme.primary,
                                ),
                                onPressed: controller.togglePassword,
                              ),
                            )),

                        const SizedBox(height: 16),

                        Obx(() => Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: controller.rememberMe.value,
                                      onChanged: controller.changeRemember,
                                      activeColor: colorScheme.primary,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                    ),
                                    Text(LocaleKeys.login_page_remember_me.tr,
                                        style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color)),
                                  ],
                                ),
                              ],
                            )),

                        const SizedBox(height: 30),
                        Obx(() => SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: controller.isLoading.value
                                    ? null
                                    : controller.login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  elevation: 8,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16)),
                                  shadowColor:
                                      colorScheme.primary.withValues(alpha: 0.5),
                                ),
                                child: controller.isLoading.value
                                    ? SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                            color: colorScheme.onPrimary,
                                            strokeWidth: 2.5),
                                      )
                                    : Text(
                                        LocaleKeys.login_page_login.tr,
                                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                              ),
                            )),

                        const SizedBox(height: 20),

                        // ثبت‌نام
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: controller.isLoading.value
                                  ? null
                                  : controller.toRegister,
                              child: Text(
                                LocaleKeys.login_page_register_action.tr,
                                style: TextStyle(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            Text(LocaleKeys.login_page_no_account.tr),
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

  Widget _buildTextFormField(BuildContext context,
      {required TextEditingController textController,
      required String label,
      required IconData icon,
      bool obscureText = false,
      String? Function(String?)? validator,
      Widget? suffixIcon,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // pick a fill color that works both in light and dark modes
    final fillColor = theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceContainerLowest.withValues(alpha: 0.04);

    return TextFormField(
      controller: textController,
      obscureText: obscureText,
      validator: validator,
      readOnly: controller.isLoading.value,
      style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.inputDecorationTheme.labelStyle ?? TextStyle(color: colorScheme.onSurface),
        prefixIcon: Icon(icon, color: colorScheme.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}
