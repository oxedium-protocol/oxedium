import 'dart:math';
import 'dart:math' as math;

extension StringExtension on String {
  String cutText({int? start, int? end}) {
    if (length < 18) {
      return this;
    }

    String startSymbols = substring(0, start ?? 4);
    String endSymbols = substring(length - (end ?? 7));
    '';
    return '$startSymbols...$endSymbols';
  }
}

extension DoubleExtension on double {
  String formatBalance() {
  int decimals;

  if (this == 0) {
    return toStringAsFixed(0);
  }

  if (this < 10) {
    decimals = 3;
  } else if (this < 100) {
    decimals = 2;
  } else if (this < 1000) {
    decimals = 1;
  } else {
    decimals = 0;
  }

  return toStringAsFixed(decimals);
}
}

extension NumExtension on num {

String formatNumber() {
  if (this >= 1e9) {
    return '${(this / 1e9).toStringAsFixed(1)}B';
  } else if (this >= 1e6) {
    return '${(this / 1e6).toStringAsFixed(1)}M';
  } else if (this >= 1e3) {
    return '${(this / 1e3).toStringAsFixed(1)}K';
  } else {
    return toString();
  }
}

double trimTo(int digits) {
  final factor = math.pow(10, digits);
  return (this * factor).truncate() / factor;
}

num smartSignificantRound() {
  if (this == 0) return 0;

  int significantDigits = 3;

  int order = (log(abs()) / ln10).floor();

  double factor = pow(10, significantDigits - 1 - order).toDouble();

  double rounded = (this * factor).round() / factor;

  if (rounded != this) {
    return rounded;
  }

  return this;
}


String formatNumWithCommas() {
    toString().contains('.')
        ? toString().replaceAll(RegExp(r'0*$'), '')
        : toString();
    List<String> parts = toString().split('.');
    String integerPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]},',
    );
    String decimalPart = parts.length > 1 ? '.${parts[1]}' : '';
    return '$integerPart$decimalPart';
  }

  double roundToSignificantFigures(int significantFigures) {
  if (this == 0) return 0;

  int digits = (log(abs()) / log(10)).floor() + 1;

  num scale = pow(10, significantFigures - digits);

  return (this * scale).round() / scale;
  }
}


