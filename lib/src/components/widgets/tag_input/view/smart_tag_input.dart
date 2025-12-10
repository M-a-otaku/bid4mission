import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../repository/smart_category_service.dart';

class SmartTagInput extends StatefulWidget {
  final void Function(String) onSelected;
  final String initialValue;
  final TextEditingController? controller;

  /// If [controller] is provided, the parent owns the text state. Otherwise
  /// the widget manages its own internal controller initialized with
  /// [initialValue].
  const SmartTagInput({Key? key, required this.onSelected, required this.initialValue, this.controller}) : super(key: key);

  @override
  State<SmartTagInput> createState() => _SmartTagInputState();
}

class _SmartTagInputState extends State<SmartTagInput> {
  TextEditingController? _internalController;
  late final TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();

  List<String> _suggestions = [];
  final List<String> _history = [];
  bool _loading = false;

  static const Duration _debounceDuration = Duration(milliseconds: 500);
  static const int _minQueryLength = 3;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _ctrl = widget.controller!;
    } else {
      _internalController = TextEditingController(text: widget.initialValue);
      _ctrl = _internalController!;
    }
    final trimmed = _ctrl.text.trim();
    if (trimmed.isNotEmpty) _history.add(trimmed);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(covariant SmartTagInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      // parent switched controllers; prefer external controller if now provided
      if (widget.controller != null) {
        _ctrl = widget.controller!;
      }
    }
  }

  void _onFocusChanged() {
    if (!mounted) return;
    // rebuild so inline suggestions hide/show with focus
    setState(() {});
  }

  void _selectSuggestion(String value) {
    if (!mounted) return;
    // Update the field visually first
    try { Get.log('SmartTagInput: selecting suggestion -> $value'); } catch (_) { print('SmartTagInput: selecting suggestion -> $value'); }
    setState(() {
      _ctrl.value = TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length));
      _suggestions = [];
      _loading = false;
    });

    // Keep history updated
    _history.remove(value);
    _history.insert(0, value);

    // Hide overlay immediately so it doesn't block taps
    // _hideOverlay();

    // Notify parent synchronously (parent should not overwrite controller if we just set it)
    try { Get.log('SmartTagInput: calling onSelected with $value'); } catch (_) { print('SmartTagInput: calling onSelected with $value'); }
    try { widget.onSelected(value); } catch (_) {}

    // restore focus so user can continue typing
    _focusNode.requestFocus();
  }

  void _onTextChanged(String value) {
    // Notify parent immediately with the typed (trimmed) value so controllers
    // don't stay with an empty category when user types but doesn't pick a chip.
    final trimmed = value.trim();
    try { Get.log('SmartTagInput: onTextChanged -> $trimmed'); } catch (_) { print('SmartTagInput: onTextChanged -> $trimmed'); }
    widget.onSelected(trimmed);

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _fetchSuggestions(value));
  }

  Future<void> _fetchSuggestions(String raw) async {
    final q = raw.trim();

    if (!mounted) return;

    if (q.length < _minQueryLength) {
      setState(() {
        _loading = false;
        _suggestions = _matchHistory(q);
      });
      return;
    }

    setState(() => _loading = true);

    List<String> service = [];
    try {
      service = await SmartCategoryService.getSuggestions(q);
    } catch (_) {
      service = [];
    }

    if (!mounted) return;

    final historyMatches = _matchHistory(q);
    final merged = <String>{};
    final List<String> list = [];
    for (var h in historyMatches) if (merged.add(h)) list.add(h);
    for (var s in service) if (merged.add(s)) list.add(s);

    setState(() {
      _loading = false;
      _suggestions = list;
    });
  }

  List<String> _matchHistory(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return List.from(_history);
    return _history.where((t) => t.toLowerCase().contains(s)).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _ctrl,
          focusNode: _focusNode,
          decoration: const InputDecoration(
            labelText: 'دسته‌بندی (مثلاً: طراحی، برنامه‌نویسی، ترجمه)',
            border: OutlineInputBorder(),
          ),
          onChanged: _onTextChanged,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return 'دسته‌بندی را وارد کنید';
            return null;
          },
        ),
        // show inline suggestions when focused and suggestions exist
        if (_focusNode.hasFocus && (_suggestions.isNotEmpty || _loading))
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _suggestionsWidget(),
          ),
      ],
    );
  }

  Widget _suggestionsWidget() {
    if (_loading) {
      return const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }

    if (_suggestions.isEmpty) return const SizedBox();

    final theme = Theme.of(context);
    try { Get.log('SmartTagInput: building suggestions (${_suggestions.length})'); } catch (_) { print('SmartTagInput: building suggestions (${_suggestions.length})'); }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8)],
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final s = _suggestions[index];
          return Material(
            color: theme.canvasColor,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (_) {
                try { Get.log('SmartTagInput: suggestion tapDown -> $s'); } catch (_) { print('SmartTagInput: suggestion tapDown -> $s'); }
                _selectSuggestion(s);
              },
              child: ListTile(
                leading: Icon(Icons.label_outline, color: theme.iconTheme.color?.withValues(alpha: 0.75), size: 18),
                title: Text(s, style: theme.textTheme.bodyMedium),
                // onTap left empty because we handle onTapDown
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    // only dispose the internal controller if we created it
    _internalController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}
