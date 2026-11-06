import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

Widget googleSignInButton(BuildContext context, {required String languageCode, required double width}) {
  return SizedBox(
    width: width,
    child: OutlinedButton.icon(
      onPressed: () async {
        final messenger = ScaffoldMessenger.of(context);
        try {
          if (!GoogleSignIn.instance.supportsAuthenticate()) throw UnsupportedError('authenticate');
          await GoogleSignIn.instance.authenticate();
        } catch (e) {
          messenger.showSnackBar(SnackBar(content: Text('Google sign-in is not configured on this device yet.')));
        }
      },
      icon: const Icon(Icons.account_circle_outlined),
      label: Text(languageCode == 'ko' ? 'Google로 계속하기' : 'Continue with Google'),
    ),
  );
}
