import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oxedium_website/utils/extensions.dart';

void main() {
  
  test("calculating earn", () {
    var number = 0.00000137412312321.roundToSignificantFigures(2);

    expect(number, equals(0.0000014));
  });

  test('format number', () {
    debugPrint(12142.formatNumber());
  });

}