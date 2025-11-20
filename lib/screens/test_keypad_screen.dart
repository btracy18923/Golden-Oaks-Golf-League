import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/compact_keypad.dart';

class TestKeypadScreen extends StatefulWidget {
  const TestKeypadScreen({super.key});

  @override
  State<TestKeypadScreen> createState() => _TestKeypadScreenState();
}

class _TestKeypadScreenState extends State<TestKeypadScreen> {
  final TextEditingController _controller = TextEditingController();
  String _keypadType = 'compact';
  String _compactValue = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Keypad Testing'),
        backgroundColor: Colors.green,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
            // Numeric Keypad Type Selector
            Text('Select Numeric Keypad Type (for golf scores):', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: [
                _buildKeypadButton('compact'),
                _buildKeypadButton('decimal'),
                _buildKeypadButton('number'),
                _buildKeypadButton('phone'),
                _buildKeypadButton('signed_decimal'),
                _buildKeypadButton('decimal_text'),
              ],
            ),
            SizedBox(height: 30),
            
            // Test Input Section
            if (_keypadType == 'compact') ...[
              // Compact Keypad Display
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.green),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('Compact Keypad with Microphone', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _compactValue.isEmpty ? 'Enter score...' : _compactValue,
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 10),
                    CompactKeypad(
                      currentValue: _compactValue,
                      allowDecimal: true,
                      maxLength: 4,
                      onInput: (value) {
                        setState(() {
                          if (value == '.' && _compactValue.contains('.')) return;
                          _compactValue += value;
                        });
                      },
                      onBackspace: () {
                        setState(() {
                          if (_compactValue.isNotEmpty) {
                            _compactValue = _compactValue.substring(0, _compactValue.length - 1);
                          }
                        });
                      },
                      onClear: () {
                        setState(() {
                          _compactValue = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              // System Keyboard Test
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text('Current: $_keypadType', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _controller,
                      keyboardType: _getKeyboardType(),
                      inputFormatters: _getInputFormatters(),
                      textInputAction: _getTextInputAction(),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 24),
                      decoration: InputDecoration(
                        hintText: 'Tap to test keypad - Look for microphone icon',
                        border: OutlineInputBorder(),
                        suffixIcon: _keypadType == 'search' ? Icon(Icons.search) : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            SizedBox(height: 20),
            
            // Display current value
            Container(
              padding: EdgeInsets.all(16),
              color: Colors.grey[100],
              child: Column(
                children: [
                  Text('Current Value:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(_controller.text.isEmpty ? 'None' : _controller.text, 
                       style: TextStyle(fontSize: 18)),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Instructions
            Container(
              padding: EdgeInsets.all(16),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue[700]),
                      SizedBox(width: 8),
                      Text('Numeric Keypad Microphone for Golf Scores:', 
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700])),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text('• BEST for golf: Try "decimal", "phone", "decimal_text"\n'
                       '• Look for microphone icon on numeric keypad\n'
                       '• "decimal_text" uses text keyboard with number filtering\n'
                       '• "phone" keypad sometimes has microphone for contact names\n'
                       '• Long-press spacebar or action button for voice input\n'
                       '• Enable "Alexa Voice Keyboard" in Fire tablet settings\n'
                       '• Voice input should work for saying numbers like "4.5", "72", etc.\n'
                       '• Test saying golf scores: "par", "bogey", "birdie", "eagle"',
                       style: TextStyle(fontSize: 12)),
                ],
              ),
            ),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                  },
                  child: Text('Dismiss Keyboard'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                ),
                ElevatedButton(
                  onPressed: () => _controller.clear(),
                  child: Text('Clear'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
              ],
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadButton(String type) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _keypadType = type;
          _controller.clear();
        });
      },
      child: Text(type),
      style: ElevatedButton.styleFrom(
        backgroundColor: _keypadType == type ? Colors.green : Colors.grey[300],
        foregroundColor: _keypadType == type ? Colors.white : Colors.black,
      ),
    );
  }

  TextInputType _getKeyboardType() {
    switch (_keypadType) {
      case 'decimal':
        return TextInputType.numberWithOptions(decimal: true);
      case 'number':
        return TextInputType.number;
      case 'phone':
        return TextInputType.phone;
      case 'signed_decimal':
        return TextInputType.numberWithOptions(decimal: true, signed: true);
      case 'decimal_text':
        return TextInputType.text; // Text keyboard but will use decimal formatter
      case 'score_entry':
        return TextInputType.numberWithOptions(decimal: true, signed: false);
      default:
        return TextInputType.numberWithOptions(decimal: true);
    }
  }

  TextInputAction _getTextInputAction() {
    switch (_keypadType) {
      case 'decimal':
        return TextInputAction.done;
      case 'number':
        return TextInputAction.done;
      case 'phone':
        return TextInputAction.done;
      case 'signed_decimal':
        return TextInputAction.done;
      case 'decimal_text':
        return TextInputAction.done;
      case 'score_entry':
        return TextInputAction.next;
      default:
        return TextInputAction.done;
    }
  }

  List<TextInputFormatter> _getInputFormatters() {
    switch (_keypadType) {
      case 'number':
        return [FilteringTextInputFormatter.digitsOnly];
      case 'decimal':
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
      case 'phone':
        return [FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\(\)\s]'))];
      case 'signed_decimal':
        return [FilteringTextInputFormatter.allow(RegExp(r'^-?\d*\.?\d*'))];
      case 'decimal_text':
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
      case 'score_entry':
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
      default:
        return [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))];
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}