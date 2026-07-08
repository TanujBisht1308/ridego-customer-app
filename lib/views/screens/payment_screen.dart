import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../controllers/ride_controller.dart';
import '../../core/constants/app_colors.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/responsive.dart';
import '../../models/payment_method.dart';
import '../widgets/app_top_bar.dart';
import '../widgets/section_card.dart';
import '../widgets/yellow_button.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _controller = RideController.instance;

  // UPI form
  final _upiCtrl = TextEditingController();
  bool _upiVerified = false;

  // Card form
  final _cardNumCtrl  = TextEditingController();
  final _cardNameCtrl = TextEditingController();
  final _expiryCtrl   = TextEditingController();
  final _cvvCtrl      = TextEditingController();
  bool _cardSaved = false;

  PaymentMethodModel get _selected =>
      _controller.paymentMethods.firstWhere((m) => m.selected);

  @override
  void dispose() {
    _upiCtrl.dispose();
    _cardNumCtrl.dispose();
    _cardNameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  void _verifyUpi() {
    if (_upiCtrl.text.contains('@')) {
      setState(() => _upiVerified = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('UPI ID verified ✓'), backgroundColor: AppColors.success),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid UPI ID (e.g. name@upi)'), backgroundColor: AppColors.danger),
      );
    }
  }

  void _saveCard() {
    if (_cardNumCtrl.text.replaceAll(' ', '').length < 16 ||
        _expiryCtrl.text.isEmpty ||
        _cvvCtrl.text.length < 3 ||
        _cardNameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all card details'), backgroundColor: AppColors.danger),
      );
      return;
    }
    setState(() => _cardSaved = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Card saved ✓'), backgroundColor: AppColors.success),
    );
  }

  bool get _readyToPay {
    switch (_selected.title) {
      case 'UPI':
        return _upiVerified;
      case 'Credit / Debit Card':
        return _cardSaved;
      default:
        return true; // Cash, Wallet — no extra step needed
    }
  }

  bool _paying = false;

  Future<void> _pay() async {
    if (!_readyToPay) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete your payment details first')),
      );
      return;
    }

    final fareValue = double.tryParse(
          _controller.summary.fare.replaceAll(RegExp(r'[^0-9.]'), ''),
        ) ??
        0;

    if (_selected.title == 'Wallet') {
      setState(() => _paying = true);
      final success = await _controller.payRideFromWallet(fareValue);
      if (!mounted) return;
      setState(() => _paying = false);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insufficient wallet balance. Choose another payment method.'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }
    }
    // Cash, UPI, Card — no real gateway yet, treated as confirmed on the spot.

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Payment of ${_controller.summary.fare} via ${_controller.summary.paymentMethod} successful'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pushNamed(context, AppRoutes.ratingReview);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(title: 'Select Payment Method'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: Responsive.pagePadding(context),
          child: Column(
            children: [
              // Payment method tiles
              ...List.generate(
                _controller.paymentMethods.length,
                (i) => _PaymentTile(
                  method: _controller.paymentMethods[i],
                  onTap: () => setState(() {
                    _controller.selectPayment(i);
                    _upiVerified = false;
                    _cardSaved = false;
                  }),
                ),
              ),

              // ── Detail form based on selection ──
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: _buildDetailForm(),
              ),

              const SizedBox(height: 22),
              YellowButton(
                text: _paying ? 'Processing...' : 'Pay ${_controller.summary.fare}',
                onTap: _paying ? null : _pay,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailForm() {
    switch (_selected.title) {
      case 'UPI':
        return _UpiForm(
          controller: _upiCtrl,
          verified: _upiVerified,
          onVerify: _verifyUpi,
        );
      case 'Credit / Debit Card':
        return _CardForm(
          numCtrl: _cardNumCtrl,
          nameCtrl: _cardNameCtrl,
          expiryCtrl: _expiryCtrl,
          cvvCtrl: _cvvCtrl,
          saved: _cardSaved,
          onSave: _saveCard,
        );
      case 'Wallet':
        return _WalletInfo(balance: _controller.walletBalance);
      default:
        return const SizedBox.shrink(); // Cash — no form
    }
  }
}

// ─── UPI form ───────────────────────────────────────────────
class _UpiForm extends StatelessWidget {
  final TextEditingController controller;
  final bool verified;
  final VoidCallback onVerify;
  const _UpiForm({required this.controller, required this.verified, required this.onVerify});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Enter UPI ID', style: TextStyle(fontWeight: FontWeight.w900, fontSize: Responsive.font(context, 15))),
          const SizedBox(height: 4),
          const Text('e.g. yourname@okaxis, 98765@paytm', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'name@upi',
                    prefixIcon: const Icon(Icons.qr_code_2, color: AppColors.primaryDark),
                    suffixIcon: verified ? const Icon(Icons.check_circle, color: AppColors.success) : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: verified ? null : onVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                child: Text(verified ? 'Verified' : 'Verify'),
              ),
            ],
          ),
          if (verified) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: const Row(
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                  SizedBox(width: 8),
                  Text('UPI ID verified. Ready to pay.', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Card form ───────────────────────────────────────────────
class _CardForm extends StatelessWidget {
  final TextEditingController numCtrl, nameCtrl, expiryCtrl, cvvCtrl;
  final bool saved;
  final VoidCallback onSave;
  const _CardForm({
    required this.numCtrl, required this.nameCtrl,
    required this.expiryCtrl, required this.cvvCtrl,
    required this.saved, required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    final focusBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryDark, width: 2));

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Card Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: Responsive.font(context, 15))),
          const SizedBox(height: 14),
          // Card number
          TextField(
            controller: numCtrl,
            keyboardType: TextInputType.number,
            maxLength: 19,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              _CardNumberFormatter(),
            ],
            decoration: InputDecoration(
              counterText: '',
              hintText: '1234 5678 9012 3456',
              labelText: 'Card Number',
              prefixIcon: const Icon(Icons.credit_card),
              border: border, focusedBorder: focusBorder,
            ),
          ),
          const SizedBox(height: 12),
          // Cardholder name
          TextField(
            controller: nameCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              hintText: 'John Doe',
              labelText: 'Cardholder Name',
              prefixIcon: const Icon(Icons.person_outline),
              border: border, focusedBorder: focusBorder,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: expiryCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 5,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _ExpiryFormatter(),
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'MM/YY',
                    labelText: 'Expiry',
                    border: border, focusedBorder: focusBorder,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: cvvCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 3,
                  obscureText: true,
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '•••',
                    labelText: 'CVV',
                    border: border, focusedBorder: focusBorder,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: saved ? null : onSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(saved ? 'Card Saved ✓' : 'Save Card'),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Wallet info ─────────────────────────────────────────────
class _WalletInfo extends StatelessWidget {
  final double balance;
  const _WalletInfo({required this.balance});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      color: AppColors.primary.withValues(alpha: 0.08),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet, color: AppColors.primaryDark, size: 28),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Wallet Balance', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text('₹${balance.toStringAsFixed(0)}',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: Responsive.font(context, 20))),
            ],
          ),
          const Spacer(),
          const Icon(Icons.check_circle, color: AppColors.success),
        ],
      ),
    );
  }
}

// ─── Formatters ──────────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final digits = nv.text.replaceAll(' ', '');
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return nv.copyWith(text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nv) {
    final digits = nv.text.replaceAll('/', '');
    var str = digits;
    if (digits.length >= 3) str = '${digits.substring(0, 2)}/${digits.substring(2)}';
    return nv.copyWith(text: str, selection: TextSelection.collapsed(offset: str.length));
  }
}

// ─── Payment tile ─────────────────────────────────────────────
class _PaymentTile extends StatelessWidget {
  final PaymentMethodModel method;
  final VoidCallback onTap;
  const _PaymentTile({required this.method, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: method.selected ? AppColors.primary : AppColors.border,
              width: method.selected ? 2 : 1),
          boxShadow: method.selected
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 16, offset: const Offset(0, 6))]
              : [],
        ),
        child: Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                  color: method.selected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(14)),
              child: Icon(method.icon, color: method.selected ? AppColors.primaryDark : AppColors.textPrimary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(method.title, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(method.subtitle,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            Icon(method.selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: method.selected ? AppColors.primaryDark : AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
