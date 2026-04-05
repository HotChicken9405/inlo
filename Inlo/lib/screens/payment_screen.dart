import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'otp_verification_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> propertyData;
  final Map<String, dynamic> room;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int nights;
  final double totalAmount;

  const PaymentScreen({
    super.key,
    required this.propertyId,
    required this.propertyData,
    required this.room,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.nights,
    required this.totalAmount,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _paymentMethod = 'card';
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String _detectedCardType = '';

  void _detectCardType(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.startsWith('4')) {
      setState(() => _detectedCardType = 'visa');
    } else if (clean.startsWith('5') || clean.startsWith('2')) {
      setState(() => _detectedCardType = 'mastercard');
    } else {
      setState(() => _detectedCardType = '');
    }
  }

  String _formatCardNumber(String value) {
    final clean = value.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < clean.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(clean[i]);
    }
    return buffer.toString();
  }

  bool _validateCard() {
    if (_emailController.text.trim().isEmpty) {
      _showSnack('Please enter your email address');
      return false;
    }
    if (!_emailController.text.contains('@')) {
      _showSnack('Please enter a valid email address');
      return false;
    }
    if (_paymentMethod == 'card') {
      final cardClean =
      _cardNumberController.text.replaceAll(' ', '');
      if (cardClean.length < 16) {
        _showSnack('Please enter a valid 16-digit card number');
        return false;
      }
      if (_expiryController.text.length < 5) {
        _showSnack('Please enter a valid expiry date');
        return false;
      }
      if (_cvvController.text.length < 3) {
        _showSnack('Please enter a valid CVV');
        return false;
      }
      if (_nameController.text.trim().isEmpty) {
        _showSnack('Please enter the cardholder name');
        return false;
      }
    }
    return true;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _sendOtpAndProceed() async {
    if (!_validateCard()) return;
    setState(() => _isLoading = true);

    // Generate 6-digit OTP
    final otp =
    (100000 + Random().nextInt(900000)).toString();

    // Send OTP via EmailJS
    try {
      final response = await http.post(
        Uri.parse(
            'https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': 'service_5zr6udv',
          'template_id': 'template_g7wvulb',
          'user_id': 'rfgvvlUuiI-wgNGr6',
          'template_params': {
            'to_email': _emailController.text.trim(),
            'to_name': _nameController.text.trim().isNotEmpty
                ? _nameController.text.trim()
                : 'Customer',
            'otp_code': otp,
            'property_name':
            widget.propertyData['propertyName'] ?? '',
            'total_amount':
            'LKR ${widget.totalAmount.toStringAsFixed(0)}',
          },
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpVerificationScreen(
              otp: otp,
              email: _emailController.text.trim(),
              propertyId: widget.propertyId,
              propertyData: widget.propertyData,
              room: widget.room,
              checkIn: widget.checkIn,
              checkOut: widget.checkOut,
              guests: widget.guests,
              nights: widget.nights,
              totalAmount: widget.totalAmount,
              paymentMethod: _paymentMethod,
            ),
          ),
        );
      } else {
        _showSnack('Failed to send OTP. Please try again.');
      }
    } catch (e) {
      _showSnack('Error sending OTP: $e');
    }

    setState(() => _isLoading = false);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Payment',
            style: TextStyle(
                color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booking summary card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.propertyData['propertyName'] ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.propertyData['city'] ?? '',
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 13),
                  ),
                  const Divider(height: 20),
                  _summaryRow(
                      'Room', widget.room['name']),
                  _summaryRow('Check-in',
                      _formatDate(widget.checkIn)),
                  _summaryRow('Check-out',
                      _formatDate(widget.checkOut)),
                  _summaryRow(
                      'Duration', '${widget.nights} nights'),
                  _summaryRow('Guests',
                      '${widget.guests} adult(s)'),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(
                        'LKR ${widget.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                            color: Colors.blue.shade600,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Email field
            const Text('YOUR EMAIL',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: Colors.black54)),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8)
                ],
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'you@example.com',
                  hintStyle:
                  TextStyle(color: Colors.grey.shade400),
                  prefixIcon: Icon(Icons.email_outlined,
                      color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment method selection
            const Text('PAYMENT METHOD',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: Colors.black54)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _methodTile(
                    value: 'card',
                    icon: Icons.credit_card,
                    label: 'Card',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _methodTile(
                    value: 'cash',
                    icon: Icons.payments_outlined,
                    label: 'Cash',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Card form
            if (_paymentMethod == 'card') ...[
              // Visual card
              Container(
                height: 190,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade800,
                      Colors.blue.shade500,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.shade300
                          .withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Circles decoration
                    Positioned(
                      top: -30,
                      right: -30,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -40,
                      left: -20,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white
                              .withOpacity(0.05),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('INLO PAY',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight:
                                      FontWeight.bold,
                                      fontSize: 16,
                                      letterSpacing: 2)),
                              if (_detectedCardType ==
                                  'visa')
                                const Text('VISA',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight:
                                        FontWeight.bold,
                                        fontSize: 20,
                                        fontStyle:
                                        FontStyle.italic))
                              else if (_detectedCardType ==
                                  'mastercard')
                                Row(children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.red
                                          .withOpacity(0.9),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset:
                                    const Offset(-10, 0),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.orange
                                            .withOpacity(0.9),
                                      ),
                                    ),
                                  ),
                                ])
                              else
                                const Icon(
                                    Icons.credit_card,
                                    color: Colors.white54),
                            ],
                          ),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                _cardNumberController
                                    .text.isEmpty
                                    ? '**** **** **** ****'
                                    : _cardNumberController
                                    .text,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    letterSpacing: 3,
                                    fontWeight:
                                    FontWeight.w600),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment
                                    .spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text('CARD HOLDER',
                                          style: TextStyle(
                                              color: Colors
                                                  .white
                                                  .withOpacity(
                                                  0.6),
                                              fontSize: 9,
                                              letterSpacing:
                                              1)),
                                      Text(
                                        _nameController
                                            .text.isEmpty
                                            ? 'FULL NAME'
                                            : _nameController
                                            .text
                                            .toUpperCase(),
                                        style:
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                    children: [
                                      Text('EXPIRES',
                                          style: TextStyle(
                                              color: Colors
                                                  .white
                                                  .withOpacity(
                                                  0.6),
                                              fontSize: 9,
                                              letterSpacing:
                                              1)),
                                      Text(
                                        _expiryController
                                            .text.isEmpty
                                            ? 'MM/YY'
                                            : _expiryController
                                            .text,
                                        style:
                                        const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight:
                                          FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Card number
              _cardField(
                label: 'CARD NUMBER',
                controller: _cardNumberController,
                hint: '1234 5678 9012 3456',
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(16),
                  _CardNumberFormatter(),
                ],
                onChanged: (v) {
                  _detectCardType(v);
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _cardField(
                      label: 'EXPIRY DATE',
                      controller: _expiryController,
                      hint: 'MM/YY',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(4),
                        _ExpiryFormatter(),
                      ],
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _cardField(
                      label: 'CVV',
                      controller: _cvvController,
                      hint: '•••',
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _cardField(
                label: 'CARDHOLDER NAME',
                controller: _nameController,
                hint: 'As shown on card',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              // Accepted cards row
              Row(
                children: [
                  Text('Accepted: ',
                      style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('VISA',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            color: Colors.blue,
                            fontStyle: FontStyle.italic)),
                  ),
                  const SizedBox(width: 6),
                  Row(children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red.withOpacity(0.9),
                        border: Border.all(
                            color: Colors.grey.shade300),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-6, 0),
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                          Colors.orange.withOpacity(0.9),
                          border: Border.all(
                              color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(-10, 0),
                      child: Text('Mastercard',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600)),
                    ),
                  ]),
                ],
              ),
            ],

            if (_paymentMethod == 'cash') ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border:
                  Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.green.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You will pay LKR ${widget.totalAmount.toStringAsFixed(0)} in cash when you check in. An OTP will be sent to verify your booking.',
                        style: TextStyle(
                            color: Colors.green.shade700,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: _isLoading
                  ? const Center(
                  child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _sendOtpAndProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12)),
                ),
                child: Text(
                  _paymentMethod == 'card'
                      ? 'Pay & Get OTP'
                      : 'Confirm & Get OTP',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text('Secured by Inlo Pay',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _methodTile({
    required String value,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.blue.shade50
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.blue.shade400
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: isSelected
                    ? Colors.blue.shade600
                    : Colors.grey.shade400,
                size: 26),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.blue.shade700
                        : Colors.grey.shade600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _cardField({
    required String label,
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8)
            ],
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle:
              TextStyle(color: Colors.grey.shade400),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// Card number formatter
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(text[i]);
    }
    final string = buffer.toString();
    return newValue.copyWith(
      text: string,
      selection:
      TextSelection.collapsed(offset: string.length),
    );
  }
}

// Expiry formatter
class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final text = newValue.text.replaceAll('/', '');
    if (text.length >= 2) {
      final formatted =
          '${text.substring(0, 2)}/${text.substring(2)}';
      return newValue.copyWith(
        text: formatted,
        selection: TextSelection.collapsed(
            offset: formatted.length),
      );
    }
    return newValue;
  }
}