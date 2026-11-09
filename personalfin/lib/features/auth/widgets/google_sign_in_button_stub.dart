import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  required bool enabled,
}) {
  return OutlinedButton.icon(
    onPressed: enabled ? onPressed : null,
    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
    label: const Text(
      'Continue with Google',
      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
    ),
  );
}