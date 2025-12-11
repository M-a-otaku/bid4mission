import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../repository/smart_category_service.dart';

class SmartTagInput extends StatefulWidget {
  final void Function(String) onSelected;
  final String initialValue;
  final TextEditingController? controller;

  
  
  
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
      
      if (widget.controller != null) {
        _ctrl = widget.controller!;
      }
    }
  }

  void _onFocusChanged() {
    if (!mounted) return;
    
    setState(() {});
  }

  void _selectSuggestion(String value) {
    if (!mounted) return;
    setState(() {
      _ctrl.value = TextEditingValue(text: value, selection: TextSelection.collapsed(offset: value.length));
      _suggestions = [];
      _loading = false;
    });

    
    _history.remove(value);
    _history.insert(0, value);


    
    try { widget.onSelected(value); } catch (_) {}

    
    _focusNode.requestFocus();
  }

  void _onTextChanged(String value) {
    
    
    final trimmed = value.trim();
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
    for (var h in historyMatches) {
      if (merged.add(h)) list.add(h);
    }
    for (var s in service) {
      if (merged.add(s)) list.add(s);
    }

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
            border: OutlineInputBorder(),
          ),
          onChanged: _onTextChanged,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          validator: (value) {
            if (value == null || value.trim().isEmpty) return ;
            return null;
          },
        ),
        
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
                _selectSuggestion(s);
              },
              child: ListTile(
                leading: Icon(Icons.label_outline, color: theme.iconTheme.color?.withValues(alpha: 0.75), size: 18),
                title: Text(s, style: theme.textTheme.bodyMedium),
                
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
    
    _internalController?.dispose();
    _focusNode.dispose();
    super.dispose();
  }
}


