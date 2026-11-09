import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

/// Custom elevated button with consistent styling
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double? height;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? ElevatedButton.icon(
            onPressed: isLoading ? null : onPressed,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(icon),
            label: Text(text),
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(text),
          );

    return SizedBox(
      width: width,
      height: height ?? AppSizes.buttonHeight,
      child: button,
    );
  }
}

/// Custom outlined button with consistent styling
class CustomOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double? width;
  final double? height;

  const CustomOutlinedButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final button = icon != null
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(text),
          )
        : OutlinedButton(
            onPressed: onPressed,
            child: Text(text),
          );

    return SizedBox(
      width: width,
      height: height ?? AppSizes.buttonHeight,
      child: button,
    );
  }
}

