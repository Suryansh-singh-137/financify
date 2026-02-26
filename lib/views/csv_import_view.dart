import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/csv_import_service.dart';
import '../theme/app_theme.dart';

class CSVImportView extends StatefulWidget {
  const CSVImportView({super.key});

  @override
  State<CSVImportView> createState() => _CSVImportViewState();
}

class _CSVImportViewState extends State<CSVImportView> {
  final CSVImportService _importService = CSVImportService();
  bool _isImporting = false;
  CSVImportResult? _result;
  String? _selectedFileName;

  Future<void> _pickAndImportFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      setState(() {
        _selectedFileName = result.files.first.name;
        _isImporting = true;
        _result = null;
      });

      final importResult = await _importService.importCSV(file);

      setState(() {
        _result = importResult;
        _isImporting = false;
      });

      if (importResult.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${importResult.parsedCount} transactions!'),
            backgroundColor: AppColors.accentGreen,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _result = CSVImportResult(
          success: false,
          errorMessage: 'Error: $e',
        );
        _isImporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      appBar: AppBar(
        title: const Text('Import Transactions'),
        backgroundColor: AppColors.primaryDark,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accentCyan.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.accentCyan, size: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'CSV Format Guide',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow('Supported Formats:', ''),
                  const SizedBox(height: 8),
                  _buildInfoRow('  1. Bank Export:', 'Date, Description, Debit, Credit, Balance'),
                  _buildInfoRow('  2. Simple:', 'Date, Merchant, Amount'),
                  _buildInfoRow('  3. Full:', 'Date, Merchant, Amount, Category'),
                  const SizedBox(height: 12),
                  _buildInfoRow('Date Format:', 'YYYY-MM-DD or DD/MM/YYYY'),
                  _buildInfoRow('Example:', '2024-01-15,Starbucks,350'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Import Button
            ElevatedButton.icon(
              onPressed: _isImporting ? null : _pickAndImportFile,
              icon: _isImporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.file_upload, size: 24),
              label: Text(
                _isImporting ? 'Importing...' : 'Select CSV File',
                style: const TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentCyan,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            if (_selectedFileName != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.insert_drive_file, color: AppColors.textSecondary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _selectedFileName!,
                        style: const TextStyle(color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Result Display
            if (_result != null) ...[
              const SizedBox(height: 24),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _result!.success
                        ? AppColors.accentGreen.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _result!.success
                          ? AppColors.accentGreen.withOpacity(0.3)
                          : AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: _result!.success
                      ? _buildSuccessResult()
                      : _buildErrorResult(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          children: [
            TextSpan(
              text: label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            if (value.isNotEmpty)
              TextSpan(
                text: ' $value',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessResult() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.accentGreen, size: 32),
              const SizedBox(width: 12),
              const Text(
                'Import Successful!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.accentGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatRow('Transactions Imported', '${_result!.parsedCount}'),
          _buildStatRow('Skipped/Invalid', '${_result!.skippedCount}'),
          _buildStatRow('Success Rate', '${_result!.successRate.toStringAsFixed(1)}%'),
          
          if (_result!.errors.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Errors:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 8),
            ..._result!.errors.take(5).map((err) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    '• $err',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.warning,
                    ),
                  ),
                )),
          ],

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorResult() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.error, color: AppColors.error, size: 32),
            const SizedBox(width: 12),
            const Text(
              'Import Failed',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _result!.errorMessage ?? 'Unknown error occurred',
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _pickAndImportFile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentCyan,
              foregroundColor: AppColors.primaryDark,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('Try Again'),
          ),
        ),
      ],
    );
  }
}
