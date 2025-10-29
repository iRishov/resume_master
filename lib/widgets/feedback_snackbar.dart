import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';

class FeedbackSnackBar {
  static void showSuccess(BuildContext context, String message) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Dismiss any existing snackbar
    scaffoldMessenger.hideCurrentSnackBar();

    // Add vibration feedback for success
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 50);
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.green.shade200, width: 1.5),
        ),
      ),
    );
  }

  static void showError(BuildContext context, String message) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Dismiss any existing snackbar
    scaffoldMessenger.hideCurrentSnackBar();

    // Add vibration feedback for error (pattern: short-long-short)
    if (await Vibration.hasVibrator()) {
      Vibration.vibrate(duration: 100); // Longer vibration for errors
    }

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200, width: 1.5),
        ),
      ),
    );
  }

  static void showInfo(BuildContext context, String message) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Dismiss any existing snackbar
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.blue.shade200, width: 1.5),
        ),
      ),
    );
  }

  static void showWarning(BuildContext context, String message) async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // Dismiss any existing snackbar
    scaffoldMessenger.hideCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: Colors.orange.shade700,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.orange.shade200, width: 1.5),
        ),
      ),
    );
  }

  // Legacy support - maintains old interface
  static void showMessage(
    BuildContext context,
    String message,
    bool isSuccess,
  ) {
    if (isSuccess) {
      showSuccess(context, message);
    } else {
      showError(context, message);
    }
  }
}
