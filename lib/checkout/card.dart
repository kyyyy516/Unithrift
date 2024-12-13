import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CardDetailsPage extends StatefulWidget {
  @override
  _CardDetailsPageState createState() => _CardDetailsPageState();
}

class _CardDetailsPageState extends State<CardDetailsPage> {
  final _cardNumberController = TextEditingController();
  final _nameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  // Custom formatter for card number (XXXX XXXX XXXX XXXX)
  final cardNumberFormatter = FilteringTextInputFormatter.digitsOnly;
  final cardNumberMaskFormatter = TextInputFormatter.withFunction(
    (oldValue, newValue) {
      final text = newValue.text.replaceAll(' ', '');
      if (text.length > 16) return oldValue;

      final buffer = StringBuffer();
      for (int i = 0; i < text.length; i++) {
        if (i > 0 && i % 4 == 0) {
          buffer.write(' ');
        }
        buffer.write(text[i]);
      }

      return TextEditingValue(
        text: buffer.toString(),
        selection: TextSelection.collapsed(offset: buffer.length),
      );
    },
    
  );

void _onTextChanged() {
    setState(() {
      // This will trigger a rebuild and update isFormValid
    });
  }

 @override
  void initState() {
    super.initState();
    // Add listeners to all controllers
    _cardNumberController.addListener(_onTextChanged);
    _nameController.addListener(_onTextChanged);
    _expiryController.addListener(_onTextChanged);
    _cvvController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    // Remove listeners when disposing
    _cardNumberController.removeListener(_onTextChanged);
    _nameController.removeListener(_onTextChanged);
    _expiryController.removeListener(_onTextChanged);
    _cvvController.removeListener(_onTextChanged);
    super.dispose();
  }

  // Custom formatter for expiry date (MM/YY)
  final expiryFormatter = TextInputFormatter.withFunction(
    (oldValue, newValue) {
      final text = newValue.text.replaceAll('/', '');
      if (text.length > 4) return oldValue;

      if (text.length >= 2) {
        return TextEditingValue(
          text: '${text.substring(0, 2)}/${text.substring(2)}',
          selection: TextSelection.collapsed(
            offset: newValue.text.length + (text.length == 2 ? 1 : 0),
          ),
        );
      }
      return newValue;
    },
  );

  


void _saveCardDetails() {
  if (isFormValid) {
    // Create a card details object
    final cardDetails = {
      'cardNumber': _cardNumberController.text,
      'cardHolder': _nameController.text,
      'expiry': _expiryController.text,
      'cvv': _cvvController.text,
    };
    
    // Optional: Navigate back
    Navigator.pop(context, cardDetails);
  }
}


  bool get isFormValid =>
      _cardNumberController.text.isNotEmpty &&
      _nameController.text.isNotEmpty &&
      _expiryController.text.isNotEmpty &&
      _cvvController.text.isNotEmpty;

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Card Details'),
      centerTitle: true,
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: Column(
              children: [
                _buildTextField(
                  controller: _cardNumberController,
                  hint: 'Card Number',
                  formatters: [
                    cardNumberFormatter,
                    cardNumberMaskFormatter,
                  ],
                  maxLength: 19,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _nameController,
                  hint: 'Name on Card',
                  formatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _expiryController,
                        hint: 'MM/YY',
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          expiryFormatter,
                        ],
                        maxLength: 5,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _cvvController,
                        hint: 'CVV',
                        formatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        maxLength: 3,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
  width: double.infinity,
  height: 50,
  child: ElevatedButton(
    onPressed: isFormValid ? _saveCardDetails : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF808569),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(25),
      ),
    ),
    child: const Text(
      'Save Card Details',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
    ),
  ),
)


        ],
      ),
    ),
  );
}


Widget _buildTextField({
  required TextEditingController controller,
  required String hint,
  List<TextInputFormatter>? formatters,
  int? maxLength,
  TextInputType? keyboardType,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: TextField(
      controller: controller,
      inputFormatters: formatters,
      keyboardType: keyboardType ?? TextInputType.text,
      maxLength: maxLength,
      onChanged: (_) => _onTextChanged(), // Add this line
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[600]),
        contentPadding: const EdgeInsets.all(16),
        border: InputBorder.none,
        counterText: '',
      ),
    ),
  );
}

}
