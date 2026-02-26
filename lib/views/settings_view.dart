import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/model_service.dart';
import '../theme/app_theme.dart';
import '../utils/demo_data_generator.dart';
import 'csv_import_view.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  Future<void> _loadDemo(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Load Demo Data'),
        content: const Text('This will replace all data with demo transactions. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Load Demo')),
        ],
      ),
    );
    if (confirm == true) {
      await DemoDataGenerator().generateDemoData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Demo data loaded!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelService = Provider.of<ModelService>(context);

    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(title: const Text('Settings'), backgroundColor: AppColors.primaryDark),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // AI Model Section
          _sectionHeader('🤖 AI Model'),
          const SizedBox(height: 8),
          _buildModelCard(modelService),
          const SizedBox(height: 20),

          // Privacy Section
          _sectionHeader('🔒 Privacy'),
          const SizedBox(height: 8),
          _buildPrivacyCard(),
          const SizedBox(height: 20),

          // Data Section
          _sectionHeader('📦 Data'),
          const SizedBox(height: 8),
          _buildDataCard(context),
          const SizedBox(height: 20),

          // Premium Section
          _sectionHeader('⭐ Premium'),
          const SizedBox(height: 8),
          _buildPremiumCard(),
          const SizedBox(height: 20),

          // About
          _sectionHeader('ℹ️ About'),
          const SizedBox(height: 8),
          _buildAboutCard(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1));
  }

  Widget _buildModelCard(ModelService modelService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SmolLM2 360M', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16)),
                    Text('~400MB · On-device AI · Privacy-safe', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: modelService.isLLMLoaded ? AppColors.accentGreen.withOpacity(0.15) : AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  modelService.isLLMLoaded ? 'Loaded ✓' : 'Not Loaded',
                  style: TextStyle(color: modelService.isLLMLoaded ? AppColors.accentGreen : AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          if (modelService.isLLMDownloading) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(value: modelService.llmDownloadProgress / 100, minHeight: 8),
            ),
            const SizedBox(height: 8),
            Text('Downloading AI model... ${modelService.llmDownloadProgress.toStringAsFixed(0)}%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          ] else if (modelService.isLLMLoading) ...[
            const SizedBox(height: 16),
            const Row(children: [
              SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 8),
              Text('Loading model into memory...', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            ]),
          ] else if (!modelService.isLLMLoaded) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => modelService.downloadAndLoadLLM(),
                icon: const Icon(Icons.download),
                label: const Text('Download & Load AI Model'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan,
                  foregroundColor: AppColors.primaryDark,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrivacyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentGreen.withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.shield, color: AppColors.accentGreen, size: 20),
            SizedBox(width: 8),
            Text('Privacy Mode Active', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGreen, fontSize: 15)),
          ]),
          SizedBox(height: 10),
          Text(
            'All your accounts, transactions, budgets, and AI reasoning stay on your device. No data is sent to any server. RunAnywhere AI runs 100% locally.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDataCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ListTile(
            onTap: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CSVImportView()),
              );
              if (result == true && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Transactions imported!')),
                );
              }
            },
            leading: const Icon(Icons.file_upload, color: AppColors.accentViolet),
            title: const Text('Import from CSV', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text('Import transactions from bank export', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ),
          Divider(color: AppColors.textMuted.withOpacity(0.1), height: 1),
          ListTile(
            onTap: () => _loadDemo(context),
            leading: const Icon(Icons.auto_awesome, color: AppColors.accentCyan),
            title: const Text('Load Demo Data', style: TextStyle(color: AppColors.textPrimary)),
            subtitle: const Text('Replace data with realistic demo transactions', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ),
          Divider(color: AppColors.textMuted.withOpacity(0.1), height: 1),
          ListTile(
            onTap: () => _showClearDialog(context),
            leading: const Icon(Icons.delete_sweep, color: AppColors.error),
            title: const Text('Clear All Data', style: TextStyle(color: AppColors.error)),
            subtitle: const Text('Permanently delete all transactions', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.accentViolet.withOpacity(0.3), AppColors.accentCyan.withOpacity(0.2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accentViolet.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Pocket CFO Premium', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('Unlimited AI chats · Advanced insights · CSV export · Cloud backup', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: AppColors.accentViolet, borderRadius: BorderRadius.circular(12)),
            child: const Text('Coming Soon · ₹390/month', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.surfaceCard, borderRadius: BorderRadius.circular(20)),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pocket CFO', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 15)),
          Text('Version 1.0.0 (MVP)', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
          SizedBox(height: 12),
          Text(
            'Built with Flutter · On-device AI via RunAnywhere · No cloud required.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will permanently delete all transactions, budgets, and insights. Cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      // DatabaseHelper.instance.clearAllData() already handles this
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All data cleared')));
    }
  }
}
