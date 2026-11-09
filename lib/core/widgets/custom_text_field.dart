import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Custom text field with consistent styling, validation indicators, and auto-focus support
class CustomTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int? maxLines;
  final int? maxLength;
  final Widget? suffixIcon;
  final String? suffixText;
  final Widget? prefixIcon;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool autofocus;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;
  final bool showValidationIndicator;
  final bool showCharacterCounter;
  final TextCapitalization textCapitalization;
  final String? semanticLabel;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.suffixIcon,
    this.suffixText,
    this.prefixIcon,
    this.readOnly = false,
    this.onTap,
    this.autofocus = false,
    this.focusNode,
    this.inputFormatters,
    this.showValidationIndicator = true,
    this.showCharacterCounter = true,
    this.textCapitalization = TextCapitalization.none,
    this.semanticLabel,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  String? _errorText;
  bool _hasInteracted = false;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_validateRealtime);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_validateRealtime);
    super.dispose();
  }

  void _validateRealtime() {
    if (!_hasInteracted) return;
    if (widget.validator == null) return;

    setState(() {
      _errorText = widget.validator!(widget.controller?.text);
    });
  }

  Widget? _buildSuffixIcon() {
    // If custom suffix provided, use it
    if (widget.suffixIcon != null) return widget.suffixIcon;

    // If no validation indicator needed, return null
    if (!widget.showValidationIndicator || widget.validator == null) {
      return null;
    }

    // Show validation indicator only after interaction
    if (!_hasInteracted) return null;

    final text = widget.controller?.text ?? '';
    if (text.isEmpty) return null;

    final isValid = _errorText == null;
    return Icon(
      isValid ? Icons.check_circle : Icons.error,
      color: isValid ? Colors.green : Colors.red,
      size: 20,
      semanticLabel: isValid ? 'Valid input' : 'Invalid input',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? widget.label,
      hint: widget.hint,
      child: TextFormField(
        controller: widget.controller,
        keyboardType: widget.keyboardType,
        obscureText: widget.obscureText,
        validator: widget.validator,
        onChanged: (value) {
          if (!_hasInteracted) {
            setState(() => _hasInteracted = true);
          }
          widget.onChanged?.call(value);
        },
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        inputFormatters: widget.inputFormatters,
        textCapitalization: widget.textCapitalization,
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          suffixIcon: _buildSuffixIcon(),
          suffixText: widget.suffixText,
          prefixIcon: widget.prefixIcon,
          errorText: _hasInteracted ? _errorText : null,
          counterText: widget.showCharacterCounter ? null : '',
        ),
      ),
    );
  }
}
