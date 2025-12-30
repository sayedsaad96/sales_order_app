import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';
import 'dart:convert';

// Bank Account Data Model
class BankAccount {
  final String bankName;
  final String branch;
  final String accountName;
  final String accountNumber;
  final String iban;

  BankAccount({
    required this.bankName,
    required this.branch,
    required this.accountName,
    required this.accountNumber,
    required this.iban,
  });

  String toShareText() {
    return '''
البنك: $bankName
الفرع: $branch
اسم الحساب: $accountName
رقم الحساب: $accountNumber
رقم الايبان: $iban
''';
  }
}

class BankAccountsPage extends StatefulWidget {
  const BankAccountsPage({super.key});

  @override
  State<BankAccountsPage> createState() => _BankAccountsPageState();
}

class _BankAccountsPageState extends State<BankAccountsPage> {
  List<BankAccount> _bankAccounts = [];
  bool _isLoading = true;
  String? _errorMessage;

  // The Google Sheet URL (Export as CSV)
  static const String _sheetUrl =
      'https://docs.google.com/spreadsheets/d/1AKbsYP6EX9jDwSktzw-M6acTsl68al8rDz8B92Nt45A/export?format=csv';

  @override
  void initState() {
    super.initState();
    _fetchBankAccounts();
  }

  Future<void> _fetchBankAccounts() async {
    try {
      final response = await http.get(Uri.parse(_sheetUrl));

      if (response.statusCode == 200) {
        // Parse CSV
        // Decode logic: Use utf8.decode to ensure Arabic text is displayed correctly.
        final decodedBody = utf8.decode(response.bodyBytes);
        final List<List<dynamic>> rows = const CsvToListConverter().convert(
          decodedBody,
        );

        if (rows.isEmpty) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'لا توجد بيانات في الملف';
          });
          return;
        }

        final List<BankAccount> loadedAccounts = [];

        // Skip header row (index 0) and iterate through data
        for (int i = 1; i < rows.length; i++) {
          final row = rows[i];
          // Ensure the row has enough columns (at least 5 based on our structure)
          // Structure: bank_name, branch, account_name, account_number, iban
          if (row.length >= 5) {
            loadedAccounts.add(
              BankAccount(
                bankName: row[0].toString(),
                branch: row[1].toString(),
                accountName: row[2].toString(),
                accountNumber: row[3].toString(), // Ensure string
                iban: row[4].toString(), // Ensure string
              ),
            );
          }
        }

        if (mounted) {
          setState(() {
            _bankAccounts = loadedAccounts;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'تعذر تحميل البيانات. تأكد من اتصالك بالإنترنت.\n$e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('الحسابات البنكية'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _fetchBankAccounts();
            },
            tooltip: 'تحديث',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 100),
            const SizedBox(height: 20),
            CircularProgressIndicator(),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _fetchBankAccounts();
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (_bankAccounts.isEmpty) {
      return const Center(child: Text('لا توجد حسابات بنكية مضافة حالياً'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _bankAccounts.length,
      itemBuilder: (context, index) {
        return _buildBankAccountCard(context, _bankAccounts[index], index + 1);
      },
    );
  }

  Widget _buildBankAccountCard(
    BuildContext context,
    BankAccount account,
    int index,
  ) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with account number and share button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.money_dollar_circle,
                      color: Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'حساب رقم $index',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(CupertinoIcons.share, color: Colors.blue),
                  onPressed: () => _shareAccount(account),
                  tooltip: 'مشاركة الحساب',
                ),
              ],
            ),
            const Divider(height: 24),

            // Bank details
            _buildDetailRow(
              CupertinoIcons.money_dollar_circle,
              'البنك',
              account.bankName,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              CupertinoIcons.location_solid,
              'الفرع',
              account.branch,
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              CupertinoIcons.person,
              'اسم الحساب',
              account.accountName,
            ),
            const SizedBox(height: 12),
            _buildCopyableDetailRow(
              context,
              CupertinoIcons.number,
              'رقم الحساب',
              account.accountNumber,
            ),
            const SizedBox(height: 12),
            _buildCopyableDetailRow(
              context,
              CupertinoIcons.creditcard,
              'رقم الايبان',
              account.iban,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.doc_on_doc, size: 18),
                    onPressed: () => _copyToClipboard(context, value, label),
                    tooltip: 'نسخ',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ $label'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareAccount(BankAccount account) {
    // ignore: deprecated_member_use
    Share.share(
      account.toShareText(),
      subject: 'معلومات الحساب البنكي - ${account.bankName}',
    );
  }
}
