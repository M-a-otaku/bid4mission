import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import '../../../../components/widgets/tag_input/view/smart_tag_input.dart';
import '../../../../infrastructure/utils/thousands_separator_input_formatter.dart';
import '../controller/edit_mission_controller.dart';
import '../../../../../generated/locales.g.dart';

class EditMissionView extends GetView<EditMissionController> {
  const EditMissionView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final backgroundTop = colorScheme.primaryContainer.withValues(alpha: 0.06);
    final backgroundBottom = colorScheme.surfaceContainerLowest.withValues(alpha: 0.02);
    final cardColor = colorScheme.surface;

    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      try {
        final m = controller.mission.value;
        if (m != null) {
          final curr = controller.budgetController.text.trim();
          if (curr.isNotEmpty && !curr.contains(',')) {
            try {
              final parsed = int.parse(curr.replaceAll(RegExp('[^0-9]'), ''));
              final formatted = intl.NumberFormat.decimalPattern('en_US').format(parsed);
              controller.budgetController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
            } catch (_) {}
          }
        }
      } catch (_) {}
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.missions_page_edit_title.tr),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary,
        elevation: 6,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [backgroundTop, backgroundBottom], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Card(
                  color: cardColor,
                  elevation: 14,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(Icons.work_outline, color: colorScheme.tertiary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(LocaleKeys.missions_page_edit_header.tr, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _sectionTitle(LocaleKeys.missions_page_section_basic_info.tr, theme, colorScheme),
                          const SizedBox(height: 8),
                          _titleField(theme, colorScheme),
                          const SizedBox(height: 12),
                          _sectionTitle(LocaleKeys.missions_page_section_description.tr, theme, colorScheme),
                          const SizedBox(height: 8),
                          _descriptionField(theme, colorScheme),
                          const SizedBox(height: 12),
                          _sectionTitle(LocaleKeys.missions_page_section_category.tr, theme, colorScheme),
                          const SizedBox(height: 8),
                          SmartTagInput(
                            controller: controller.categoryController,
                            initialValue: controller.selectedCategory.value,
                            onSelected: (selectedTag) {
                              controller.selectedCategory.value = selectedTag;
                            },
                          ),
                          const SizedBox(height: 12),
                          _sectionTitle(LocaleKeys.missions_page_section_budget_deadline.tr, theme, colorScheme),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _budgetField(theme, colorScheme)),
                              const SizedBox(width: 12),
                              Expanded(child: _deadlinePicker(context)),
                            ],
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: Obx(() => FloatingActionButton(
        onPressed: controller.isLoading.value ? null : controller.submitEdit,
        backgroundColor: theme.floatingActionButtonTheme.backgroundColor ?? colorScheme.primary,
        foregroundColor: theme.floatingActionButtonTheme.foregroundColor ?? colorScheme.onPrimary,
        child: controller.isLoading.value
            ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: theme.floatingActionButtonTheme.foregroundColor ?? colorScheme.onPrimary, strokeWidth: 2))
            : Text(LocaleKeys.missions_page_fab_save.tr),
      )),
    );
  }

  Widget _sectionTitle(String text, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.tertiary,
              borderRadius: BorderRadius.circular(6),
              boxShadow: [BoxShadow(color: colorScheme.tertiary.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2))],
            ),
          ),
          const SizedBox(width: 10),
          Text(text, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
        ],
      ),
    );
  }

  Widget _titleField(ThemeData theme, ColorScheme colorScheme) => TextFormField(
    controller: controller.titleController,
    validator: controller.validateTitle,
    decoration: _inputDecoration(LocaleKeys.missions_page_title_label.tr, Icons.title, theme, colorScheme),
    style: theme.textTheme.bodyLarge,
    autovalidateMode: AutovalidateMode.onUserInteraction,
  );

  Widget _descriptionField(ThemeData theme, ColorScheme colorScheme) => TextFormField(
    controller: controller.descriptionController,
    validator: controller.validateDescription,
    maxLines: 5,
    decoration: _inputDecoration(LocaleKeys.missions_page_description_label.tr, Icons.description, theme, colorScheme),
    style: theme.textTheme.bodyMedium,
    autovalidateMode: AutovalidateMode.onUserInteraction,
  );

  Widget _budgetField(ThemeData theme, ColorScheme colorScheme) => Obx(() {
    
    try {
      final m = controller.mission.value;
      if (m != null) {
        final current = controller.budgetController.text.trim();
        
        if (current.isNotEmpty && !current.contains(',')) {
          try {
            final parsed = int.parse(current.replaceAll(RegExp('[^0-9]'), ''));
            final formatted = intl.NumberFormat.decimalPattern('en_US').format(parsed);
            controller.budgetController.value = TextEditingValue(text: formatted, selection: TextSelection.collapsed(offset: formatted.length));
          } catch (_) {}
        }
      }
    } catch (_) {}

    return TextFormField(
      controller: controller.budgetController,
      validator: controller.validateBudget,
      keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
      inputFormatters: [ThousandsSeparatorInputFormatter(locale: 'en_US')],
      decoration: _inputDecoration(LocaleKeys.missions_page_budget_label_create.tr, Icons.attach_money, theme, colorScheme),
      style: theme.textTheme.bodyLarge,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  });

  Widget _deadlinePicker(BuildContext context) => Obx(() => InkWell(
    onTap: () => controller.pickDeadline(context),
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surfaceContainerLowest.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.selectedDeadline.value == null
                  ? LocaleKeys.missions_page_deadline_select_hint.tr
                  : LocaleKeys.missions_page_deadline_label_format.trParams({'date': intl.DateFormat('yyyy/MM/dd HH:mm').format(controller.selectedDeadline.value!)}),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Icon(Icons.arrow_drop_down, color: Theme.of(context).iconTheme.color),
        ],
      ),
    ),
  ));

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme, ColorScheme colorScheme) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: colorScheme.primary),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    filled: true,
    fillColor: theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceContainerLowest.withValues(alpha: 0.04),
    labelStyle: theme.inputDecorationTheme.labelStyle ?? theme.textTheme.bodyMedium,
  );
}


