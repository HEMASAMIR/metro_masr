import 'package:dio/dio.dart';

class PaymobService {
  // ────────────────────────────────────────────────────────────────────────
  // TODO: Replace these with your REAL Paymob Account details from the dashboard
  // ────────────────────────────────────────────────────────────────────────
  static const String apiKey = 'ZXlKaGJHY2lPaUpJVXpVeE1pSXNJblI1Y0NJNklrcFhWQ0o5LmV5SmpiR0Z6Y3lJNklrMWxjbU5vWVc1MElpd2ljSEp2Wm1sc1pWOXdheUk2TVRFd016VTVOQ3dpYm1GdFpTSTZJakUzTmpNME1ERTJOalV1TlRNeU5pSjkuXzhmdnNLSUtQbGdkcTJacDd6OWZUTVY2dDI5WGFqM0txbjVoWVRwc3JRcVdLN1QxRFFNbk91M2ZGWkQzTl9rV2pwSGFzUDZpNGV2UU5TWjNwZUNjT3c=';
  static const String integrationId = '5389274'; // From Payment Integrations Screenshot
  static const String iframeId = '976962'; // From Iframes Screenshot
  
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://accept.paymob.com/api',
      receiveDataWhenStatusError: true,
    ),
  );

  /// Step 1: Authentication Request
  static Future<String> _getAuthToken() async {
    try {
      final response = await _dio.post(
        '/auth/tokens',
        data: {
          'api_key': apiKey,
        },
      );
      return response.data['token'];
    } catch (e) {
      throw Exception('Paymob Auth Error: $e');
    }
  }

  /// Step 2: Order Registration
  static Future<int> _getOrderId({
    required String authToken,
    required String amountCents,
  }) async {
    try {
      final response = await _dio.post(
        '/ecommerce/orders',
        data: {
          'auth_token': authToken,
          'delivery_needed': 'false',
          'amount_cents': amountCents,
          'currency': 'EGP',
          'items': [],
        },
      );
      return response.data['id'];
    } catch (e) {
      throw Exception('Paymob Order Error: $e');
    }
  }

  /// Step 3: Payment Key Request
  static Future<String> _getPaymentKey({
    required String authToken,
    required String amountCents,
    required int orderId,
  }) async {
    try {
      final response = await _dio.post(
        '/acceptance/payment_keys',
        data: {
          'auth_token': authToken,
          'amount_cents': amountCents,
          'expiration': 3600,
          'order_id': orderId.toString(),
          'billing_data': {
            'apartment': 'NA',
            'email': 'user@rafiqmetro.com', // Replace with actual user data if available
            'floor': 'NA',
            'first_name': 'Rafiq',
            'street': 'NA',
            'building': 'NA',
            'phone_number': '+201000000000',
            'shipping_method': 'NA',
            'postal_code': 'NA',
            'city': 'Cairo',
            'country': 'EG',
            'last_name': 'User',
            'state': 'NA'
          },
          'currency': 'EGP',
          'integration_id': integrationId,
        },
      );
      return response.data['token'];
    } catch (e) {
      throw Exception('Paymob Payment Key Error: $e');
    }
  }

  /// Master function to execute all 3 steps and get the final token
  static Future<String> getFinalPaymentToken(double amountEGP) async {
    try {
      // Amount in Paymob must be in CENTS (e.g. 10 EGP = 1000 cents)
      final amountCents = (amountEGP * 100).toInt().toString();

      // 1. Get Auth Token
      final authToken = await _getAuthToken();
      
      // 2. Get Order ID
      final orderId = await _getOrderId(authToken: authToken, amountCents: amountCents);
      
      // 3. Get Payment Key (Final Token)
      final paymentKey = await _getPaymentKey(
        authToken: authToken,
        amountCents: amountCents,
        orderId: orderId,
      );

      return paymentKey;
    } catch (e) {
      throw Exception('Paymob Flow Failed: $e');
    }
  }
}
