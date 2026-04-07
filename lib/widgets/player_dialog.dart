// -----------------------------------------------------------------------------
// PLAYER DIALOG
// -----------------------------------------------------------------------------
//
// Opens the full screen player as a slide up dialog.
// Extracted here because every screen that plays a track uses this exact call.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

import 'full_player_sheet.dart';

void showFullPlayerDialog(BuildContext context) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, animation, secondaryAnimation) =>
        const FullPlayerSheet(),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: child,
      );
    },
  );
}
