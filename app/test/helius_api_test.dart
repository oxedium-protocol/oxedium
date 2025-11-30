import 'package:flutter_test/flutter_test.dart';
import 'package:solana/solana.dart';
import 'package:oxedium_website/service/helius_api.dart';

void main() {
  
  test('getSignatureStatus', () async {
    await HeliusApi.waitingSignatureStatus(signature: '31zu31HWTi7bU6ydwNuuuLGBek5gmqaSbUvGNcfNWnRD8rhJ4T6FT3Wcgp4aau8PUeWcR7jivRvFwGdBXTRVCcKH', expectedStatus: Commitment.finalized);
  });

}