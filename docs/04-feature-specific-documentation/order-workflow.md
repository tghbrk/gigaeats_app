Of course. Here is a comprehensive explanation of the complete order workflow in the GigaEats application, from creation to completion, detailing the roles, status changes, and technical implementation.

### Introduction to the GigaEats Order Workflow

The GigaEats order workflow is designed as a robust, three-sided B2B2C process involving **Sales Agents**, **Vendors**, and **End Customers**. The system leverages a combination of a Flutter frontend, a Supabase backend, and automated database triggers to ensure a seamless and transparent order lifecycle.

The process begins with a Sales Agent creating an order on behalf of a customer and ends with the Vendor fulfilling it, with automated systems handling status updates, notifications, and commission calculations along the way.

---

### The Order Lifecycle: A Step-by-Step Walkthrough

The workflow can be broken down into five main stages, with different user roles taking action at each step.

#### **Stage 1: Order Creation (Sales Agent)**

1.  **Action (Sales Agent):** The Sales Agent uses the app to browse vendors, add items to a cart, and create an order for a customer.
    *   **UI:** This process starts in screens like `lib/features/sales_agent/presentation/screens/vendors_screen.dart` and `.../vendor_details_screen.dart`. The agent adds items to the cart, which is managed by the `CartNotifier` in `lib/features/sales_agent/presentation/providers/cart_provider.dart`.
    *   The final order is submitted through the `lib/features/orders/presentation/screens/create_order_screen.dart`.

2.  **Technical Implementation:**
    *   The `CreateOrderScreen` gathers all necessary information (customer, delivery details, notes).
    *   On submission, it calls the `createOrder` method in `lib/features/orders/presentation/providers/order_provider.dart`.
    *   The `OrdersNotifier` then calls the `OrderRepository.createOrder` method in `lib/features/orders/data/repositories/order_repository.dart`.
    *   This repository method constructs an `Order` object and sends it to the Supabase backend. A crucial detail here is the use of `getAuthenticatedClient()` to ensure the request is made with the logged-in agent's credentials, which is essential for RLS (Row Level Security) policies.
    *   A database function `generate_order_number()` is triggered on insertion to create a unique, human-readable order number (e.g., `GE-20241201-0001`), as planned in `docs/ORDER_MANAGEMENT_SYSTEM.md`.

3.  **Status Change:** The order is created with an initial status of `OrderStatus.pending`.

#### **Stage 2: Order Confirmation (Vendor)**

1.  **Action (Vendor):** The Vendor receives the new order on their dashboard and must either accept or reject it.
    *   **UI:** The order appears in the `VendorOrdersScreen` (`lib/features/orders/presentation/screens/vendor_orders_screen.dart`). The vendor can view the details in `VendorOrderDetailsScreen` (`.../vendor_order_details_screen.dart`).
    *   This screen provides action buttons like "Accept Order" and "Reject Order".

2.  **Technical Implementation:**
    *   Tapping "Accept Order" calls the `updateOrderStatus` method in `OrderRepository`, setting the new status to `confirmed`.
    *   This update triggers the `handle_order_status_change()` function in the Supabase database, as defined in `docs/GigaEatsBackendImplementationPlan.md`.
    *   This trigger automatically creates a record in the `order_status_history` table, logging the change from `pending` to `confirmed`.

3.  **Status Change:** `pending` → `confirmed`.

4.  **Notifications:** The `handle_order_status_change()` trigger also inserts a new row into the `order_notifications` table, notifying the Sales Agent that the order has been confirmed. The app's `NotificationCenter` (`lib/features/notifications/presentation/widgets/notification_center.dart`) listens for these updates.

#### **Stage 3: Preparation & Fulfillment (Vendor)**

1.  **Action (Vendor):** The Vendor prepares the food. As they progress, they update the order status.
    *   **UI:** From the `VendorOrderDetailsScreen`, the vendor uses action buttons like "Start Preparing" and "Mark as Ready".

2.  **Technical Implementation:**
    *   Each button press calls `OrderRepository.updateOrderStatus` with the new status (`preparing`, then `ready`).
    *   The `handle_order_status_change()` database trigger is fired for each update. It automatically populates the corresponding timestamp fields in the `orders` table (`preparation_started_at`, `ready_at`).
    *   Real-time updates are sent to the Sales Agent via Supabase's real-time subscriptions, managed by providers like `ordersStreamProvider` and `enhancedOrdersStreamProvider`.

3.  **Status Change:** `confirmed` → `preparing` → `ready`.

#### **Stage 4: Delivery & Completion (Vendor/Sales Agent)**

1.  **Action (Vendor/Sales Agent):** Once the order is ready, it is dispatched for delivery or picked up. The final step is capturing proof of delivery.
    *   **UI:** Depending on the delivery method, a driver or Sales Agent uses the `ProofOfDeliveryCapture` widget (`lib/features/orders/presentation/widgets/proof_of_delivery_capture.dart`) to take a photo and get a GPS location.
    *   The `DeliveryProofTestScreen` (`lib/shared/test_screens/delivery_proof_test_screen.dart`) is used for testing this workflow.

2.  **Technical Implementation:**
    *   The `ProofOfDeliveryCapture` widget uses the `FileUploadService` to upload the photo to a dedicated Supabase Storage bucket (`delivery-proofs`), as specified in `docs/DELIVERY_PROOF_API_REFERENCE.md`.
    *   It also uses the `LocationService` (`lib/core/services/location_service.dart`) to get accurate GPS coordinates.
    *   Once captured, the `onProofCaptured` callback is triggered, which calls the `OrderRepository.storeDeliveryProof` method.
    *   This method inserts a new record into the `delivery_proofs` table.
    *   A database trigger, `handle_delivery_proof_creation()`, automatically updates the corresponding order's status to `delivered` and sets the `actual_delivery_time`.

3.  **Status Change:** `ready` → `out_for_delivery` → `delivered`.

#### **Stage 5: Post-Completion (System)**

1.  **Action (System):** Once an order is marked as `delivered`, the system performs final automated tasks.
    *   **UI:** The Sales Agent sees their earnings update in the `CommissionScreen` (`lib/features/sales_agent/presentation/screens/commission_screen.dart`).

2.  **Technical Implementation:**
    *   **Commission Calculation:** The status change to `delivered` fires the `calculate_commission_on_delivery()` trigger, as defined in `docs/GigaEatsBackendImplementationPlan.md`.
    *   This function calculates the commission based on the order's subtotal and the agent's commission rate (defaulting to 7%) and inserts a record into the `commission_transactions` table.
    *   **Customer Statistics:** The `update_customer_stats_on_delivery()` trigger updates the `customers` table with the new total order count and total amount spent for that customer.

---

### Technical Deep Dive

#### **Order Status & Real-time Updates**

The entire workflow hinges on the `OrderStatus` enum defined in `lib/features/orders/data/models/order.dart`.

```dart
// lib/features/orders/data/models/order.dart
enum OrderStatus {
  pending,
  confirmed,
  preparing,
  ready,
  outForDelivery,
  delivered,
  cancelled,
}
```

The frontend initiates status changes through the `OrderRepository`, but the backend database triggers handle the crucial side effects like history logging and timestamping. This makes the system robust and ensures data integrity.

Real-time updates are powered by Supabase's `stream()` method, which is wrapped in the `OrderRepository`:

```dart
// lib/features/orders/data/repositories/order_repository.dart
Stream<List<Order>> getOrdersStream({OrderStatus? status}) {
  return executeStreamQuery(() async* {
    // ... filtering logic ...
    dynamic streamBuilder = supabase.from('orders').stream(primaryKey: ['id']);
    // ...
  });
}
```

This stream is consumed by Riverpod providers like `ordersStreamProvider`, which automatically rebuilds the UI (e.g., `VendorOrdersScreen`) whenever an order changes in the database.

#### **Payment & Commission Flow**

-   **Payment:** While the full payment gateway integration is planned for a later phase, the database schema is ready. The `process-payment` Edge Function in `supabase/functions/process-payment/index.ts` will handle secure transactions, creating records in the `payment_transactions` table.
-   **Commission:** Commissions are calculated **after an order is successfully delivered**. The `calculate_commission_on_delivery()` trigger ensures this is an automated and reliable process that cannot be bypassed. This prevents agents from earning commissions on cancelled or failed orders.

This automated, trigger-based workflow ensures that the system is reliable, auditable, and requires minimal manual intervention, which is crucial for a scalable platform like GigaEats.