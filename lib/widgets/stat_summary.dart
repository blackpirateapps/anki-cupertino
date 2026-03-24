import 'package:flutter/cupertino.dart';

class StatSummary extends StatelessWidget {
  const StatSummary({
    required this.label,
    required this.value,
    required this.suffix,
    super.key,
  });

  final String label;
  final String value;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: CupertinoColors.systemGrey,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: value,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' $suffix',
                style: const TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

