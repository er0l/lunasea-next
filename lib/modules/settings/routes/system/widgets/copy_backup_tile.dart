import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lunasea/core.dart';
import 'package:lunasea/database/config.dart';

class SettingsSystemBackupRestoreCopyBackupTile extends StatelessWidget {
  const SettingsSystemBackupRestoreCopyBackupTile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LunaBlock(
      title: 'Copy Configuration to Clipboard',
      body: const [TextSpan(text: 'Copy the current configuration as JSON to the clipboard.')],
      trailing: const LunaIconButton(icon: Icons.copy_all_rounded),
      onTap: () async => _copy(context),
    );
  }

  Future<void> _copy(BuildContext context) async {
    try {
      String data = LunaConfig().export();
      await Clipboard.setData(ClipboardData(text: data));
      showLunaSuccessSnackBar(
        title: 'Copied to Clipboard',
        message: 'Configuration JSON copied to clipboard',
      );
    } catch (error, stack) {
      LunaLogger().error('Failed to copy backup to clipboard', error, stack);
      showLunaErrorSnackBar(
        title: 'Copy Failed',
        error: error,
      );
    }
  }
}
