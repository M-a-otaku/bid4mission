import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/services.dart';
import '../../../../components/widgets/tag_input/view/smart_tag_input.dart';
import '../../../../infrastructure/utils/thousands_separator_input_formatter.dart';
import '../controller/create_mission_controller.dart';
import '../../../../../generated/locales.g.dart';

class CreateMissionView extends GetView<CreateMissionController> {
  const CreateMissionView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // design tokens for a more attractive, contrasting layout
    final backgroundTop = colorScheme.primaryContainer.withValues(alpha: 0.06);
    final backgroundBottom = colorScheme.surfaceContainerLowest.withValues(alpha: 0.02);
    final cardColor = colorScheme.surface;
    // inputs use a subtle surfaceVariant so they stand out against card
    final inputFill = theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceContainerLowest.withValues(alpha: 0.04);

    return Scaffold(
      // AppBar: use a prominent primaryContainer so it contrasts with background
      appBar: AppBar(
        title: Text('missions_page_create_title'.tr),
        backgroundColor: theme.appBarTheme.backgroundColor ?? colorScheme.primary,
        foregroundColor: theme.appBarTheme.foregroundColor ?? colorScheme.onPrimary,
        elevation: 6,
        centerTitle: true,
        // subtle bottom border via shadow color
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),

      // Background: subtle gradient between background and surface to create depth
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [backgroundTop, backgroundBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.6)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: controller.formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // header row with icon and title
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
                              Text('missions_page_create_header'.tr, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _sectionTitle('missions_page_section_basic_info'.tr, theme, colorScheme),
                          const SizedBox(height: 8),
                          _titleField(theme, inputFill, colorScheme),
                          const SizedBox(height: 12),

                          _sectionTitle('missions_page_section_description'.tr, theme, colorScheme),
                          const SizedBox(height: 8),
                          _descriptionField(theme, inputFill, colorScheme),
                          const SizedBox(height: 12),

                          _sectionTitle('missions_page_section_category'.tr, theme, colorScheme),
                          const SizedBox(height: 8),
                          SmartTagInput(
                            controller: controller.categoryController,
                            initialValue: controller.selectedCategory.value,
                            onSelected: (selectedTag) {
                              try { Get.log('CreateMissionView: onSelected -> $selectedTag'); } catch (_) { print('CreateMissionView: onSelected -> $selectedTag'); }
                              controller.selectedCategory.value = selectedTag;
                              try { Get.log('CreateMissionView: controller.selectedCategory -> ${controller.selectedCategory.value}'); } catch (_) { print('CreateMissionView: controller.selectedCategory -> ${controller.selectedCategory.value}'); }
                            },
                          ),
                          const SizedBox(height: 12),

                          _sectionTitle('missions_page_section_budget_deadline'.tr, theme, colorScheme),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(child: _budgetField(theme, inputFill, colorScheme)),
                              const SizedBox(width: 12),
                              Expanded(child: _deadlinePicker(theme, colorScheme)),
                            ],
                          ),

                          const SizedBox(height: 20),
                          // removed inline cancel/submit buttons; submission moved to FAB
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

      // floatingActionButton: keep hidden (we use action buttons in form) but leave for accessibility
      floatingActionButton: Obx(() {
        final isLoading = controller.isLoading.value;
        // disable FAB when loading
        return FloatingActionButton(
          onPressed: isLoading ? null : () async {
            // try submit; if form invalid, show validation messages
            await controller.submitMission();
          },
          backgroundColor: theme.floatingActionButtonTheme.backgroundColor ?? colorScheme.primary,
          foregroundColor: theme.floatingActionButtonTheme.foregroundColor ?? colorScheme.onPrimary,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: theme.floatingActionButtonTheme.foregroundColor ?? colorScheme.onPrimary,
                    strokeWidth: 2,
                  ),
                )
              : Text('missions_page_fab_publish'.tr),
        );
      }),
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
              boxShadow: [
                BoxShadow(color: colorScheme.tertiary.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }

  Widget _titleField(ThemeData theme, Color fillColor, ColorScheme colorScheme) => TextFormField(
        controller: controller.titleController,
        validator: controller.validateTitle,
        decoration: _inputDecoration('missions_page_title_label'.tr, Icons.title, theme, fillColor, colorScheme),
        style: theme.textTheme.bodyLarge,
      );

  Widget _descriptionField(ThemeData theme, Color fillColor, ColorScheme colorScheme) => TextFormField(
        controller: controller.descriptionController,
        validator: controller.validateDescription,
        maxLines: 5,
        decoration: _inputDecoration('missions_page_description_label'.tr, Icons.description, theme, fillColor, colorScheme),
        style: theme.textTheme.bodyMedium,
      );

  Widget _budgetField(ThemeData theme, Color fillColor, ColorScheme colorScheme) => TextFormField(
        controller: controller.budgetController,
        validator: controller.validateBudget,
        keyboardType: const TextInputType.numberWithOptions(decimal: false, signed: false),
        inputFormatters: [ThousandsSeparatorInputFormatter(locale: 'en_US')],
        decoration: _inputDecoration('missions_page_budget_label_create'.tr, Icons.attach_money, theme, fillColor, colorScheme),
        style: theme.textTheme.bodyLarge,
      );

  Widget _deadlinePicker(ThemeData theme, ColorScheme colorScheme) => Obx(() => InkWell(
         onTap: controller.pickDeadline,
         borderRadius: BorderRadius.circular(12),
         child: Container(
           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
           decoration: BoxDecoration(
             color: theme.inputDecorationTheme.fillColor ?? colorScheme.surfaceContainerLowest.withValues(alpha: 0.04),
             borderRadius: BorderRadius.circular(12),
             border: Border.all(color: theme.dividerColor),
           ),
           child: Row(
             children: [
               Icon(Icons.calendar_today, color: colorScheme.primary),
               const SizedBox(width: 12),
               Expanded(
                 child: Text(
                   controller.selectedDeadline.value == null
                       ? 'missions_page_deadline_select_hint'.tr
                       : 'missions_page_deadline_label_format'.trParams({'date': intl.DateFormat('yyyy/MM/dd HH:mm').format(controller.selectedDeadline.value!)}),
                   style: theme.textTheme.bodyMedium,
                 ),
               ),
               Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
             ],
           ),
         ),
       ));

  InputDecoration _inputDecoration(String label, IconData icon, ThemeData theme, Color fillColor, ColorScheme colorScheme) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: fillColor,
        labelStyle: theme.inputDecorationTheme.labelStyle ?? theme.textTheme.bodyMedium,
      );
}
