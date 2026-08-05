import 'package:flutter/material.dart';

import '../../data/app_database.dart';
import '../../widgets/safe_sheet_scaffold.dart';

enum PhotoAction {
  view,
  resetView,
  editCaption,
  makePrimary,
  adjustAlignment,
  delete,
}

Future<PhotoAction?> showPhotoActionsSheet({
  required BuildContext context,
  required ImageAssetRecord image,
  bool canMakePrimary = false,
  bool canAdjustAlignment = false,
}) => showSafeModalSheet<PhotoAction>(
  context: context,
  presentation: SafeSheetPresentation.compact,
  builder: (sheetContext) => SafeSheetScaffold(
    title: 'Fotoacties',
    contentSized: true,
    actions: const [],
    body: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.open_in_full),
          title: const Text('Bekijken'),
          onTap: () => Navigator.pop(sheetContext, PhotoAction.view),
        ),
        ListTile(
          leading: const Icon(Icons.edit_note_outlined),
          title: Text(
            image.caption?.trim().isNotEmpty == true
                ? 'Beschrijving wijzigen'
                : 'Beschrijving toevoegen',
          ),
          onTap: () => Navigator.pop(sheetContext, PhotoAction.editCaption),
        ),
        if (canMakePrimary)
          ListTile(
            leading: const Icon(Icons.center_focus_strong),
            title: const Text('Als scorefoto gebruiken'),
            onTap: () => Navigator.pop(sheetContext, PhotoAction.makePrimary),
          ),
        if (canAdjustAlignment)
          ListTile(
            leading: const Icon(Icons.crop_free),
            title: const Text('Uitlijning aanpassen'),
            onTap: () =>
                Navigator.pop(sheetContext, PhotoAction.adjustAlignment),
          ),
        ListTile(
          leading: Icon(
            Icons.delete_outline,
            color: Theme.of(sheetContext).colorScheme.error,
          ),
          title: Text(
            'Foto verwijderen',
            style: TextStyle(color: Theme.of(sheetContext).colorScheme.error),
          ),
          onTap: () => Navigator.pop(sheetContext, PhotoAction.delete),
        ),
      ],
    ),
  ),
);
