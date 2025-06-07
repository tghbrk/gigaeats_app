import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/orders/data/models/delivery_method.dart';

// Delivery Proof Realtime Provider
final deliveryProofRealtimeProvider = StreamProvider.family<ProofOfDelivery?, String>((ref, orderId) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('delivery_proofs')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .map((data) {
        if (data.isEmpty) return null;
        return ProofOfDelivery.fromJson(data.first);
      });
});

// Delivery Status Realtime Provider
final deliveryStatusRealtimeProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, orderId) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('orders')
      .stream(primaryKey: ['id'])
      .eq('id', orderId)
      .map((data) {
        if (data.isEmpty) return null;
        final order = data.first;
        return {
          'status': order['status'],
          'delivery_info': order['delivery_info'],
          'estimated_delivery': order['estimated_delivery'],
          'actual_delivery': order['actual_delivery'],
          'updated_at': order['updated_at'],
        };
      });
});

// Driver Location Realtime Provider (for live tracking)
final driverLocationRealtimeProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, orderId) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('driver_locations')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .map((data) {
        if (data.isEmpty) return null;
        final location = data.first;
        return {
          'latitude': location['latitude'],
          'longitude': location['longitude'],
          'accuracy': location['accuracy'],
          'heading': location['heading'],
          'speed': location['speed'],
          'updated_at': location['updated_at'],
        };
      });
});

// Order Updates Realtime Provider
final orderUpdatesRealtimeProvider = StreamProvider.family<List<Map<String, dynamic>>, String>((ref, orderId) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('order_status_history')
      .stream(primaryKey: ['id'])
      .eq('order_id', orderId)
      .order('created_at', ascending: false);
});

// Delivery Notifications Realtime Provider
final deliveryNotificationsRealtimeProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final supabase = Supabase.instance.client;
  
  return supabase
      .from('delivery_notifications')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .limit(50);
});
