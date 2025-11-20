import 'package:flutter/material.dart';

class CompactKeypad extends StatefulWidget {
  final Function(String) onInput;
  final Function()? onClear;
  final Function()? onBackspace;
  final String currentValue;
  final bool allowDecimal;
  final int maxLength;

  const CompactKeypad({
    super.key,
    required this.onInput,
    this.onClear,
    this.onBackspace,
    this.currentValue = '',
    this.allowDecimal = true,
    this.maxLength = 4,
  });

  @override
  State<CompactKeypad> createState() => _CompactKeypadState();
}

class _CompactKeypadState extends State<CompactKeypad> {
  String _status = 'Compact Keypad Ready';

  Widget _buildKeypadButton(String text, {Color? color, double? fontSize}) {
    return Expanded(
      child: Container(
        height: 50,
        margin: const EdgeInsets.all(2),
        child: ElevatedButton(
          onPressed: () {
            if (widget.currentValue.length < widget.maxLength) {
              widget.onInput(text);
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.grey[200],
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: fontSize ?? 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(String text, IconData icon, VoidCallback onPressed, {Color? color}) {
    return Expanded(
      child: Container(
        height: 50,
        margin: const EdgeInsets.all(2),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color ?? Colors.blue[200],
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.zero,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16),
              Text(
                text,
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status row
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              _status,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          // Row 1: 1, 2, 3
          Row(
            children: [
              _buildKeypadButton('1'),
              _buildKeypadButton('2'),
              _buildKeypadButton('3'),
            ],
          ),
          
          // Row 2: 4, 5, 6
          Row(
            children: [
              _buildKeypadButton('4'),
              _buildKeypadButton('5'),
              _buildKeypadButton('6'),
            ],
          ),
          
          // Row 3: 7, 8, 9
          Row(
            children: [
              _buildKeypadButton('7'),
              _buildKeypadButton('8'),
              _buildKeypadButton('9'),
            ],
          ),
          
          // Row 4: ., 0, backspace
          Row(
            children: [
              if (widget.allowDecimal)
                _buildKeypadButton('.', color: Colors.orange[200])
              else
                const Expanded(child: SizedBox()),
              _buildKeypadButton('0'),
              _buildActionButton(
                'DEL',
                Icons.backspace,
                () {
                  if (widget.onBackspace != null) {
                    widget.onBackspace!();
                  }
                },
                color: Colors.red[300],
              ),
            ],
          ),
          
          // Row 5: Enter, Clear  
          Row(
            children: [
              _buildActionButton(
                'ENTER',
                Icons.check,
                () {
                  setState(() {
                    _status = 'Value entered: ${widget.currentValue}';
                  });
                },
                color: Colors.green[300],
              ),
              _buildActionButton(
                'CLEAR',
                Icons.clear,
                () {
                  if (widget.onClear != null) {
                    widget.onClear!();
                  }
                  setState(() {
                    _status = 'Cleared';
                  });
                },
                color: Colors.orange[300],
              ),
            ],
          ),
        ],
      ),
    );
  }

}