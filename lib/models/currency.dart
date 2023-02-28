// ignore_for_file: non_constant_identifier_names

import 'package:freezed_annotation/freezed_annotation.dart';

part 'currency.freezed.dart';
part 'currency.g.dart';

@freezed
class Currency with _$Currency {
  factory Currency({
    String? symbol,
    String? name,
    String? symbol_native,
    int? decimal_digits,
    double? rounding,
    String? code,
    String? name_plural,
  }) = _Currency;

  factory Currency.fromJson(Map<String, dynamic> json) =>
      _$CurrencyFromJson(json);
}
