import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart';

Widget buildGoogleSignInButton({
  required VoidCallback onPressed,
  required bool enabled,
}) {
  return IgnorePointer(
    ignoring: !enabled,
    child: SizedBox(
      height: 50,
      child: renderButton(),
    ),
  );
}