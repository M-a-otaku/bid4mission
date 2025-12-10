import 'package:flutter/material.dart';
import 'package:get/Get.dart';
import '../../../../generated/locales.g.dart';
import '../../../infrastructure/commons/role.dart';
import '../controllers/register_controller.dart';

class RegisterView extends GetView<RegisterController> {
  const RegisterView({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return Scaffold(
      body: Stack(
        children: [
          _backgroundGradient(context),
          _headerAnimated(context),
          _body(context, size, isTablet),
        ],
      ),
    );
  }

  Widget _backgroundGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary,
            colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _headerAnimated(BuildContext context) {
    return Positioned(
      top: 90,
      left: 0,
      right: 0,
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: -50, end: 0),
            duration: const Duration(milliseconds: 1250),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, value),
                child: Hero(tag: "register_icon", child: _icon(context)),
              );
            },
          ),
          const SizedBox(height: 18),
          Text(
            LocaleKeys.register_page_welcome.tr,
            style: TextStyle(
              fontSize: 33,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          Text(
            LocaleKeys.register_page_information.tr,
            style: TextStyle(
              fontSize: 17,
              color: Theme.of(context).colorScheme.onPrimary.withAlpha(220),
            ),
          ),
        ],
      ),
    );
  }

  Widget _icon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).cardColor.withValues(alpha: 0.95),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Icon(
        Icons.person_add_rounded,
        size: 55,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _body(BuildContext context, Size size, bool isTablet) {
    return Form(
      key: controller.formKey,
      child: Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
                size.width * 0.07, size.height * 0.12, size.width * 0.07, 40),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor.withValues(alpha: 0.92),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(45),
                topRight: Radius.circular(45),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 20,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: Column(
              children: [
                _inputCard(context, size, isTablet),
                const SizedBox(height: 20),
                _login(context),
                const SizedBox(height: 30),
                _registerButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputCard(BuildContext context, Size size, bool isTablet) {
    return Material(
      elevation: 9,
      shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.28),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            _firstname(context),
            const SizedBox(height: 16),
            _lastname(context),
            const SizedBox(height: 16),
            _username(context),
            const SizedBox(height: 16),
            _password(context),
            const SizedBox(height: 16),
            _repeatPassword(context),
            const SizedBox(height: 16),
            _roleDropdown(context),
          ],
        ),
      ),
    );
  }

  Widget _firstname(BuildContext context) {
    return Obx(
      () => TextFormField(
        controller: controller.firstnameController,
        readOnly: controller.isLoading.value,
        validator: (v) {
          final base = controller.validate(v);
          if (base != null) return base;
          if (controller.firstnameError.value.isNotEmpty) return controller.firstnameError.value;
          return null;
        },
        decoration: InputDecoration(
          labelText: LocaleKeys.register_page_firstname_label.tr,
          prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor.withValues(alpha: 0.35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _lastname(BuildContext context) {
    return Obx(
      () => TextFormField(
        controller: controller.lastnameController,
        readOnly: controller.isLoading.value,
        validator: (v) {
          final base = controller.validate(v);
          if (base != null) return base;
          if (controller.lastnameError.value.isNotEmpty) return controller.lastnameError.value;
          return null;
        },
        decoration: InputDecoration(
          labelText: LocaleKeys.register_page_lastname_label.tr,
          prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor.withValues(alpha: 0.35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _username(BuildContext context) {
    return Obx(
      () => TextFormField(
        controller: controller.usernameController,
        readOnly: controller.isLoading.value,
        validator: (v) {
          final base = controller.validateUsername(v);
          if (base != null) return base;
          if (controller.usernameError.value.isNotEmpty) return controller.usernameError.value;
          return null;
        },
        decoration: InputDecoration(
          labelText: LocaleKeys.login_page_username.tr,
          prefixIcon: Icon(Icons.person_outline, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor.withValues(alpha: 0.35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _password(BuildContext context) {
    return Obx(
      () => TextFormField(
        controller: controller.passwordController,
        obscureText: controller.isPasswordVisible.value,
        readOnly: controller.isLoading.value,
        validator: (v) {
          final base = controller.validatePassword(v);
          if (base != null) return base;
          if (controller.passwordError.value.isNotEmpty) return controller.passwordError.value;
          return null;
        },
        decoration: InputDecoration(
          labelText: LocaleKeys.login_page_password.tr,
          prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
          suffixIcon: IconButton(
            onPressed: controller.onPressed,
            icon: Icon(
              controller.isPasswordVisible.value
                  ? Icons.visibility
                  : Icons.visibility_off_outlined,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor.withValues(alpha: 0.35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _repeatPassword(BuildContext context) {
    return Obx(
      () => TextFormField(
        controller: controller.repeatPassController,
        obscureText: controller.isRepeatPasswordVisible.value,
        readOnly: controller.isLoading.value,
        validator: controller.validateRepeatPassword,
        decoration: InputDecoration(
          labelText: LocaleKeys.register_page_repeat_password.tr,
          prefixIcon: Icon(Icons.lock_outline, color: Theme.of(context).colorScheme.primary),
          suffixIcon: IconButton(
            onPressed: controller.onPressedRepeat,
            icon: Icon(
              controller.isRepeatPasswordVisible.value
                  ? Icons.visibility
                  : Icons.visibility_off_outlined,
            ),
          ),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor.withValues(alpha: 0.35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _roleDropdown(BuildContext context) {
    return Obx(
      () => DropdownButtonFormField<Role>(
        value: controller.selectedRole.value,
        validator: (value) => value == null ? LocaleKeys.register_page_role_validator.tr : null,
        items: [
          DropdownMenuItem(value: Role.employer, child: Text(LocaleKeys.register_page_role_employer.tr)),
          DropdownMenuItem(value: Role.hunter, child: Text(LocaleKeys.register_page_role_hunter.tr)),
        ],
        onChanged: (value) {
          if (value != null) controller.selectedRole.value = value;
        },
        decoration: InputDecoration(
          labelText: LocaleKeys.register_page_role_label.tr,
          prefixIcon: Icon(Icons.work_outline, color: Theme.of(context).colorScheme.primary),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).cardColor.withValues(alpha: 0.35),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _login(BuildContext context) {
    return InkWell(
      onTap: controller.isLoading.value ? null : Get.back,
      child: Text(
        LocaleKeys.register_page_back_login.tr,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black,
        ),
      ),
    );
  }

  Widget _registerButton(BuildContext context) {
    return Obx(() => AnimatedContainer(
          duration: const Duration(milliseconds: 1250),
          curve: Curves.easeOut,
          width: double.infinity,
          height: 55,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: controller.isLoading.value
                  ? [Colors.grey.shade800, Colors.grey.shade400]
                  : [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primaryContainer],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              )
            ],
          ),
          child: InkWell(
            onTap: controller.isLoading.value ? null : controller.doRegister,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: controller.isLoading.value
                  ? CircularProgressIndicator(color: Theme.of(context).colorScheme.onPrimary)
                  : Text(
                      LocaleKeys.register_page_register.tr,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
            ),
          ),
        ));
  }
}
