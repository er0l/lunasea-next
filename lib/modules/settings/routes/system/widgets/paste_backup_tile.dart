import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/database/config.dart';

class SettingsSystemBackupRestorePasteBackupTile extends StatelessWidget {
  const SettingsSystemBackupRestorePasteBackupTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LunaBlock(
      title: 'Restore Configuration from Clipboard',
      body: const [TextSpan(text: 'Paste a configuration JSON from the clipboard to restore.')],
      trailing: const LunaIconButton(icon: Icons.paste_rounded),
      onTap: () async => _restore(context),
    );
  }

  Future<void> _restore(BuildContext context) async {
    try {
      ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text?.isNotEmpty ?? false) {
        await LunaConfig().import(context, data!.text!);
        showLunaSuccessSnackBar(
          title: 'Restored from Clipboard',
          message: 'Configuration successfully restored',
        );
      } else {
        showLunaErrorSnackBar(
          title: 'Restore Failed',
          message: 'Clipboard is empty or contains invalid data',
        );
      }
    } catch (error, stack) {
      LunaLogger().error('Failed to restore backup from clipboard', error, stack);
      showLunaErrorSnackBar(
        title: 'Restore Failed',
        error: error,
      );
    }
  }
}
