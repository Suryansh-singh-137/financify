import 'dart:io';
import 'package:csv/csv.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';
import '../database/database_helper.dart';

class CSVImportService {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final _uuid = const Uuid();

  /// Parse CSV file and return list of transactions
  /// Expected format: Date, Merchant/Description, Amount, Category (optional)
  /// Supports multiple formats:
  /// - Bank exports: Date, Description, Debit/Credit, Amount, Balance
  /// - Simple: Date, Merchant, Amount
  Future<CSVImportResult> importCSV(File file) async {
    try {
      final csvString = await file.readAsString();
      final rows = const CsvToListConverter().convert(csvString);
      
      if (rows.isEmpty) {
        return CSVImportResult(
          success: false,
          errorMessage: 'CSV file is empty',
        );
      }

      // Detect format and parse
      final result = await _parseRows(rows);
      
      return result;
    } catch (e) {
      return CSVImportResult(
        success: false,
        errorMessage: 'Failed to read CSV: $e',
      );
    }
  }

  Future<CSVImportResult> _parseRows(List<List<dynamic>> rows) async {
    int parsed = 0;
    int skipped = 0;
    final List<String> errors = [];

    // Skip header row
    final dataRows = rows.skip(1).toList();

    for (int i = 0; i < dataRows.length; i++) {
      try {
        final row = dataRows[i];
        if (row.isEmpty || row.length < 3) {
          skipped++;
          continue;
        }

        final transaction = _parseRow(row);
        if (transaction != null) {
          await _db.insertTransaction(transaction);
          parsed++;
        } else {
          skipped++;
        }
      } catch (e) {
        errors.add('Row ${i + 2}: $e');
        skipped++;
      }
    }

    return CSVImportResult(
      success: true,
      parsedCount: parsed,
      skippedCount: skipped,
      errors: errors,
    );
  }

  Transaction? _parseRow(List<dynamic> row) {
    try {
      // Try different formats
      if (row.length >= 5) {
        // Bank export format: Date, Description, Debit, Credit, Balance
        return _parseBankFormat(row);
      } else if (row.length >= 3) {
        // Simple format: Date, Merchant, Amount, [Category]
        return _parseSimpleFormat(row);
      }
      return null;
    } catch (e) {
      print('Error parsing row: $e');
      return null;
    }
  }

  Transaction? _parseBankFormat(List<dynamic> row) {
    final dateStr = row[0].toString();
    final description = row[1].toString();
    final debit = _parseAmount(row[2]);
    final credit = _parseAmount(row[3]);

    final amount = debit > 0 ? debit : credit;
    if (amount <= 0) return null;

    final type = debit > 0 ? TransactionType.expense : TransactionType.income;
    final date = _parseDate(dateStr);
    if (date == null) return null;

    // Auto-categorize based on merchant name
    final category = _autoCategorize(description);

    return Transaction(
      id: _uuid.v4(),
      amount: amount,
      merchant: description,
      category: category,
      description: description,
      date: date,
      type: type,
      importedFrom: 'csv',
    );
  }

  Transaction? _parseSimpleFormat(List<dynamic> row) {
    final dateStr = row[0].toString();
    final merchant = row[1].toString();
    final amount = _parseAmount(row[2]);

    if (amount <= 0) return null;

    final date = _parseDate(dateStr);
    if (date == null) return null;

    final category = row.length > 3 
        ? row[3].toString().toLowerCase()
        : _autoCategorize(merchant);

    return Transaction(
      id: _uuid.v4(),
      amount: amount,
      merchant: merchant,
      category: category,
      description: merchant,
      date: date,
      type: TransactionType.expense,
      importedFrom: 'csv',
    );
  }

  DateTime? _parseDate(String dateStr) {
    try {
      // Try multiple date formats
      final formats = [
        RegExp(r'(\d{4})-(\d{2})-(\d{2})'), // YYYY-MM-DD
        RegExp(r'(\d{2})/(\d{2})/(\d{4})'), // DD/MM/YYYY
        RegExp(r'(\d{2})-(\d{2})-(\d{4})'), // DD-MM-YYYY
      ];

      for (final format in formats) {
        final match = format.firstMatch(dateStr);
        if (match != null) {
          if (format == formats[0]) {
            // YYYY-MM-DD
            return DateTime.parse(dateStr);
          } else {
            // DD/MM/YYYY or DD-MM-YYYY
            final day = int.parse(match.group(1)!);
            final month = int.parse(match.group(2)!);
            final year = int.parse(match.group(3)!);
            return DateTime(year, month, day);
          }
        }
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  double _parseAmount(dynamic value) {
    try {
      if (value is num) return value.toDouble();
      final str = value.toString().replaceAll(',', '').replaceAll('₹', '').trim();
      return double.tryParse(str) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  String _autoCategorize(String merchant) {
    final lower = merchant.toLowerCase();

    // Food & Dining
    if (lower.contains('zomato') || lower.contains('swiggy') || 
        lower.contains('restaurant') || lower.contains('cafe') ||
        lower.contains('food') || lower.contains('mcdonald') ||
        lower.contains('starbucks') || lower.contains('domino')) {
      return 'food';
    }

    // Transport
    if (lower.contains('uber') || lower.contains('ola') || 
        lower.contains('rapido') || lower.contains('metro') ||
        lower.contains('petrol') || lower.contains('fuel')) {
      return 'transport';
    }

    // Shopping
    if (lower.contains('amazon') || lower.contains('flipkart') ||
        lower.contains('myntra') || lower.contains('meesho') ||
        lower.contains('mall') || lower.contains('shop')) {
      return 'shopping';
    }

    // Bills & Subscriptions
    if (lower.contains('netflix') || lower.contains('spotify') ||
        lower.contains('prime') || lower.contains('subscription') ||
        lower.contains('electricity') || lower.contains('internet') ||
        lower.contains('recharge')) {
      return 'bills';
    }

    // Entertainment
    if (lower.contains('movie') || lower.contains('cinema') ||
        lower.contains('pvr') || lower.contains('bookmyshow') ||
        lower.contains('steam') || lower.contains('playstation')) {
      return 'entertainment';
    }

    // Health
    if (lower.contains('pharma') || lower.contains('hospital') ||
        lower.contains('doctor') || lower.contains('gym') ||
        lower.contains('medical')) {
      return 'health';
    }

    return 'others';
  }
}

class CSVImportResult {
  final bool success;
  final int parsedCount;
  final int skippedCount;
  final List<String> errors;
  final String? errorMessage;

  CSVImportResult({
    required this.success,
    this.parsedCount = 0,
    this.skippedCount = 0,
    this.errors = const [],
    this.errorMessage,
  });

  double get successRate => 
      (parsedCount + skippedCount) > 0 
          ? (parsedCount / (parsedCount + skippedCount)) * 100 
          : 0;
}
