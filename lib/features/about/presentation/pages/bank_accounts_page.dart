import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

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

class BankAccountsPage extends StatelessWidget {
  const BankAccountsPage({super.key});

  // Bank accounts data
  static final List<BankAccount> bankAccounts = [
    BankAccount(
      bankName: 'البنك الاهلي المصري',
      branch: 'المحله الكبري',
      accountName: 'مصنع الحفناوي للنسيج الدائري والتريكو والملابس الجاهزة',
      accountNumber: '6053130666990103039',
      iban: 'EG41000360531306669901030390',
    ),
    BankAccount(
      bankName: 'بنك الامارات دبي',
      branch: 'المحله الكبري',
      accountName: 'مصنع الحفناوي للنسيج الدائري والتريكو والملابس الجاهزة',
      accountNumber: '7329280999508',
      iban: 'EG040014005800007329280999508',
    ),
    BankAccount(
      bankName: 'ابو ظبي الاول مصر',
      branch: 'مكرم عبيد - مصر',
      accountName: 'مصنع الحفناوي للنسيج الدائري والتريكو والملابس الجاهزة',
      accountNumber: '001643570002',
      iban: 'EG040019000900000016435700002',
    ),
    BankAccount(
      bankName: 'ابو ظبي الاول مصر',
      branch: 'مكرم عبيد - مصر',
      accountName: 'شركة انكس للتجارة',
      accountNumber: '003169450001',
      iban: 'EG760019000900000003169450001',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الحسابات البنكية'), centerTitle: true),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: bankAccounts.length,
            itemBuilder: (context, index) {
              return _buildBankAccountCard(context, bankAccounts[index], index + 1);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBankAccountCard(
    BuildContext context,
    BankAccount account,
    int accountNumber,
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
                      Icons.account_balance,
                      color: Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'حساب رقم $accountNumber',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.blue),
                  onPressed: () => _shareAccount(account),
                  tooltip: 'مشاركة الحساب',
                ),
              ],
            ),
            const Divider(height: 24),

            // Bank details
            _buildDetailRow(Icons.account_balance, 'البنك', account.bankName),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.location_on, 'الفرع', account.branch),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.person, 'اسم الحساب', account.accountName),
            const SizedBox(height: 12),
            _buildCopyableDetailRow(
              context,
              Icons.numbers,
              'رقم الحساب',
              account.accountNumber,
            ),
            const SizedBox(height: 12),
            _buildCopyableDetailRow(
              context,
              Icons.credit_card,
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
                    icon: const Icon(Icons.copy, size: 18),
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
