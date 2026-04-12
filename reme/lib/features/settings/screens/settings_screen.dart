import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app.dart';
import '../../../core/services/backup_service.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDark;

    return Scaffold(
      appBar: AppBar(title: const Text('REME')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Settings',
              style: TextStyle(
                  color: context.onSurfaceMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5)),
          const SizedBox(height: 8),
          _SectionLabel('Appearance'),
          _SettingsTile(
            icon: isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
            iconColor: AppTheme.primary,
            title: 'Theme',
            subtitle: isDark ? 'Dark mode' : 'Light mode',
            trailing: Switch(
              value: isDark,
              activeThumbColor: AppTheme.primary,
              onChanged: (_) => themeProvider.toggle(),
            ),
          ),
          _SectionLabel('Data'),
          _SettingsTile(
            icon: Icons.upload_rounded,
            iconColor: AppTheme.success,
            title: 'Backup Data',
            subtitle: 'Save a backup to device storage',
            onTap: () => _backup(context),
          ),
          _SettingsTile(
            icon: Icons.download_rounded,
            iconColor: AppTheme.warning,
            title: 'Restore Data',
            subtitle: 'Restore from a previous backup',
            onTap: () => _showRestoreList(context),
          ),
          _SectionLabel('Support'),
          _SettingsTile(
            icon: Icons.bug_report_outlined,
            iconColor: AppTheme.error,
            title: 'Report a Bug',
            subtitle: 'Send feedback to the developer',
            onTap: () => _reportBug(context),
          ),
          _SectionLabel('About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppTheme.secondary,
            title: 'About REME',
            subtitle: 'Version 1.0.0',
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  Future<void> _backup(BuildContext context) async {
    final path = await BackupService.exportBackup();
    if (!context.mounted) return;
    if (path != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Backup Saved'),
          content: Text(
              'Saved to:\n\n$path\n\nYou can find this in your Files app under Android/data.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Backup failed'),
        backgroundColor: AppTheme.error,
      ));
    }
  }

  Future<void> _showRestoreList(BuildContext context) async {
    final backups = await BackupService.listBackups();
    if (!context.mounted) return;

    if (backups.isEmpty) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No Backups Found'),
          content: const Text(
              'No backup files found. Create a backup first using "Backup Data".'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK')),
          ],
        ),
      );
      return;
    }

    final dateFmt = DateFormat('MMM d, yyyy  h:mm a');
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetCtx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: sheetCtx.surfaceVariant,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Select Backup to Restore',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          const SizedBox(height: 8),
          ...backups.map((f) {
            final name = f.path
                .split('/')
                .last
                .replaceAll('reme_backup_', '')
                .replaceAll('.db', '');
            DateTime? date;
            try {
              date = DateFormat('yyyyMMdd_HHmmss').parse(name);
            } catch (_) {}
            return ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppTheme.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.storage_rounded,
                    color: AppTheme.warning, size: 20),
              ),
              title: Text(date != null ? dateFmt.format(date) : name),
              subtitle: Text(
                  '${(File(f.path).lengthSync() / 1024).toStringAsFixed(1)} KB'),
              trailing:
                  const Icon(Icons.restore_rounded, color: AppTheme.primary),
              onTap: () {
                Navigator.pop(sheetCtx);
                _confirmRestore(context, f.path);
              },
            );
          }),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Future<void> _confirmRestore(BuildContext context, String path) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
            'This will replace all current data. The app needs to restart after restoring.\n\nContinue?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore',
                style: TextStyle(color: AppTheme.warning)),
          ),
        ],
      ),
    );
    if (confirm != true || !context.mounted) return;

    final ok = await BackupService.restoreBackup(path);
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(ok ? 'Restore Complete' : 'Restore Failed'),
        content: Text(ok
            ? 'Data restored. Please close and reopen the app to apply changes.'
            : 'Could not restore. Make sure the file is a valid REME backup.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _reportBug(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'rein.codeux@gmail.com',
      queryParameters: {
        'subject': 'REME Bug Report',
        'body':
            'Describe the issue:\n\n\nSteps to reproduce:\n\n\nDevice & Android version:\n',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No email app found. Contact: rein.codeux@gmail.com')),
      );
    }
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.restaurant_menu_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('REME'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version 1.0.0',
                style: TextStyle(color: context.onSurfaceMuted, fontSize: 13)),
            const SizedBox(height: 12),
            const Text(
              'REME is an offline recipe and business management app for small food businesses. '
              'Track recipe costs, record sales, manage inventory, and monitor staff labor — all in one place, no internet needed.',
            ),
            const SizedBox(height: 12),
            Text('Built with Flutter',
                style: TextStyle(color: context.onSurfaceMuted, fontSize: 12)),
            const SizedBox(height: 4),
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('mailto:rein.codeux@gmail.com')),
              child: const Text('rein.codeux@gmail.com',
                  style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 12,
                      decoration: TextDecoration.underline)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
            color: context.onSurfaceMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: context.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            context.isDark ? Border.all(color: context.surfaceVariant) : null,
        boxShadow: context.isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2))
              ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: TextStyle(
                color: context.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(color: context.onSurfaceMuted, fontSize: 12)),
        trailing: trailing ??
            (onTap != null
                ? Icon(Icons.chevron_right_rounded,
                    color: context.onSurfaceMuted)
                : null),
      ),
    );
  }
}
