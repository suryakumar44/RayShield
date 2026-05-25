import 'package:user_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:user_app/success.dart';

class PaymentGatewayScreen extends StatefulWidget {
  final int id;
  final int amt;

  const PaymentGatewayScreen({super.key, required this.id, required this.amt});

  @override
  State<PaymentGatewayScreen> createState() => _PaymentGatewayScreenState();
}

class _PaymentGatewayScreenState extends State<PaymentGatewayScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  final TextEditingController cardNumber = TextEditingController();
  final TextEditingController cardName = TextEditingController();
  final TextEditingController expiry = TextEditingController();
  final TextEditingController cvv = TextEditingController();

  // Updated Theme Colors
  static const Color scaffoldBg = Color(0xFF0D0D0D);
  static const Color cardFill = Color(0xFF1A1A1A);
  

  Future<void> checkout() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);
    try {
      await supabase
          .from('tbl_cart')
          .update({'cart_status': 2}).eq('booking_id', widget.id);

      await supabase.from('tbl_booking').update({
        'booking_status': 2,
        'booking_amount': widget.amt
      }).eq('booking_id', widget.id);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) =>  PaymentSuccessPage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment Failed")),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Secure Checkout",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              
              /// CREDIT CARD UI
              Container(
                height: 210,
                width: double.infinity,
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color.fromARGB(255, 42, 255, 170), Color.fromARGB(255, 28, 220, 254)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromARGB(255, 59, 255, 252).withOpacity(.3),
                      blurRadius: 25,
                      offset: const Offset(0, 12),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        
                        const Icon(Icons.contactless, color: Colors.white70, size: 28),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      cardNumber.text.isEmpty
                          ? "XXXX XXXX XXXX XXXX"
                          : cardNumber.text,
                      style: const TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2.5),
                    ),
                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("CARD HOLDER", 
                              style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.1)),
                            const SizedBox(height: 4),
                            Text(
                              cardName.text.isEmpty ? "FULL NAME" : cardName.text.toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("EXPIRES", 
                              style: TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1.1)),
                            const SizedBox(height: 4),
                            Text(
                              expiry.text.isEmpty ? "MM/YY" : expiry.text,
                              style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ],
                        )
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 35),
              const Text("Payment Details", 
                style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),

              /// PAYMENT FORM
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: cardNumber,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(16),
                        CardFormatter()
                      ],
                      decoration: inputDecoration("Card Number", Icons.credit_card_outlined),
                      validator: (value) => (value == null || value.replaceAll(" ", "").length != 16)
                          ? "Enter valid 16 digit card number" : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: cardName,
                      style: const TextStyle(color: Colors.white),
                      textCapitalization: TextCapitalization.words,
                      decoration: inputDecoration("Card Holder Name", Icons.person_outline),
                      validator: (value) => (value == null || value.isEmpty) ? "Enter name" : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: expiry,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                              ExpiryFormatter()
                            ],
                            decoration: inputDecoration("Expiry MM/YY", Icons.calendar_today_outlined),
                            validator: (value) {
                              if (value == null || value.length != 5) return "Invalid";
                              final parts = value.split('/');
                              int month = int.parse(parts[0]);
                              int year = int.parse(parts[1]);
                              if (month < 1 || month > 12) return "Invalid";
                              final now = DateTime.now();
                              int currentYear = now.year % 100;
                              int currentMonth = now.month;
                              if (year < currentYear || (year == currentYear && month < currentMonth)) return "Expired";
                              return null;
                            },
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: TextFormField(
                            
                            controller: cvv,
                            style: const TextStyle(color: Colors.white),
                            keyboardType: TextInputType.number,
                            obscureText: true,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3)
                            ],
                            decoration: inputDecoration("CVV", Icons.lock_outline),
                            validator: (value) => (value == null || value.length != 3) ? "Invalid" : null,
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 40),

                    /// PAY BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : checkout,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color.fromARGB(255, 47, 255, 245),
                          foregroundColor: const Color.fromARGB(255, 0, 0, 0),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isProcessing
                            ? const SizedBox(height: 24, width: 24, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                "Pay ₹${widget.amt}",
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.white24, size: 18),
                        SizedBox(width: 8),
                        Text("Secure Payment Powered by UvSense",
                          style: TextStyle(color: Colors.white24, fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
      prefixIcon: Icon(icon, color: const Color.fromARGB(255, 58, 248, 255), size: 20),
      filled: true,
      fillColor: cardFill,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.white12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color.fromARGB(255, 56, 255, 232), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}

class CardFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll(" ", "");
    if (text.length > 16) return oldValue;
    var newText = "";
    for (int i = 0; i < text.length; i++) {
      if (i % 4 == 0 && i != 0) newText += " ";
      newText += text[i];
    }
    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String text = newValue.text.replaceAll("/", "");
    if (text.length > 4) return oldValue;
    if (text.length >= 3) {
      text = "${text.substring(0, 2)}/${text.substring(2)}";
    }
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}