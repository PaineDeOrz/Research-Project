// -----------------------------------------------------------------------------
// STYLED BOTTOM SHEET
// -----------------------------------------------------------------------------
//
// Wrapper around showModalBottomSheet with the app's standard styling.
//
// -----------------------------------------------------------------------------

import 'package:flutter/material.dart';

Future<T?> showStyledBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    useRootNavigator: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: builder,
  );
}
