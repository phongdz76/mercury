# MoMo Payment Integration - Flutter Implementation

This implementation provides premium subscription functionality using MoMo payment gateway for your Flutter chat application.

## Features Implemented

### 1. Payment Models (`lib/models/payment.dart`)

- `Payment` - Complete payment model with all necessary fields
- `PaymentRequest` - Request model for creating payments
- `PaymentResponse` - Response model from payment API
- `PaymentStatus` - Enum for payment states (pending, completed, failed, cancelled, refunded)
- `PremiumPlan` - Model for premium subscription plans

### 2. Payment Service (`lib/services/payment_service.dart`)

- `createPayment()` - Create new payment transaction
- `getPayment()` - Get payment by ID
- `getPaymentHistory()` - Get user's payment history
- `createMoMoPayment()` - Simplified method for MoMo payments
- Helper methods for formatting, validation, and status management

### 3. Payment Provider (`lib/providers/payment_provider.dart`)

- State management for payments using Provider pattern
- Caching of payment data and premium plans
- Real-time payment status updates
- Payment history management
- Integration with existing chat provider

### 4. UI Components

#### Premium Purchase Screen (`lib/screens/premium_purchase_screen.dart`)

- Beautiful premium upgrade interface
- Plan selection (Monthly/Yearly)
- MoMo payment integration
- Real-time payment status
- Automatic redirection to MoMo app

#### Payment History Screen (`lib/screens/payment_history_screen.dart`)

- Complete payment transaction history
- Payment status tracking
- Quick payment retry functionality
- Beautiful summary cards

#### Premium Status Widget (`lib/widgets/premium_status_widget.dart`)

- Reusable premium status display
- Premium feature gate component
- Upgrade prompts and dialogs
- Integration with chat provider for premium status

### 5. Integration Points

#### Profile Screen Integration

- Premium status display
- Quick access to payment history (for premium users)
- Upgrade button (for non-premium users)
- Premium badge display

#### Conversations Screen Integration

- Non-intrusive premium promotion banner
- Context-aware upgrade prompts

## Usage Examples

### 1. Basic Payment Creation

```dart
// Create a payment for monthly premium
final paymentProvider = Provider.of<PaymentProvider>(context, listen: false);

final response = await paymentProvider.createPayment(
  plan: 'monthly',
  amount: 99000,
  description: 'Monthly premium subscription',
);

if (response?.success == true && response?.payUrl != null) {
  // Redirect user to MoMo payment URL
  await launchUrl(Uri.parse(response!.payUrl!));
}
```

### 2. Premium Feature Gating

```dart
// Wrap premium features with PremiumFeatureGate
PremiumFeatureGate(
  featureName: 'HD Video Calls',
  description: 'Make crystal clear video calls with premium quality',
  child: VideoCallButton(),
  premiumChild: AdvancedVideoCallButton(), // Optional premium version
)
```

### 3. Premium Status Display

```dart
// Show premium status anywhere in the app
PremiumStatusWidget(
  showFullCard: false, // true for full upgrade card, false for banner
  onUpgradePressed: () {
    // Custom upgrade action
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => PremiumPurchaseScreen(),
    ));
  },
)
```

### 4. Payment History Access

```dart
// Load and display payment history
final paymentProvider = Provider.of<PaymentProvider>(context);
await paymentProvider.loadPaymentHistory();

// Access payment data
final payments = paymentProvider.payments;
final totalSpent = paymentProvider.getTotalSpent();
final pendingPayments = paymentProvider.getPendingPayments();
```

## Configuration

### 1. Dependencies Added

Add to `pubspec.yaml`:

```yaml
dependencies:
  url_launcher: ^6.3.1 # For opening MoMo payment URLs
```

### 2. Provider Setup

In `main.dart`, add PaymentProvider:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (context) => ChatProvider()),
    ChangeNotifierProvider(create: (context) => PaymentProvider()),
    // ... other providers
  ],
  child: MyApp(),
)
```

### 3. API Endpoints

Update your backend to handle these endpoints:

- `POST /payments` - Create payment
- `GET /payments/:id` - Get payment by ID
- `GET /payments` - Get payment history
- `POST /webhooks/payment/momo` - MoMo webhook (backend only)

## Premium Plans

Default plans are configured in the code:

### Monthly Plan

- **Price**: 99,000 VND
- **Duration**: 30 days
- **Features**: Unlimited message history, Large file sharing, HD video calls, Priority support, Custom themes

### Yearly Plan (Most Popular)

- **Price**: 950,000 VND (20% discount)
- **Duration**: 365 days
- **Features**: All monthly features + Advanced analytics + 20% savings

## Payment Flow

1. **User initiates payment**

   - Selects premium plan
   - App calls `createPayment()` API
   - Server creates payment record and MoMo payment URL

2. **Payment processing**

   - User redirected to MoMo app/website
   - User completes payment in MoMo
   - MoMo sends webhook to backend

3. **Payment completion**

   - Backend validates MoMo webhook
   - Updates payment status
   - Upgrades user to premium
   - User receives confirmation

4. **Premium activation**
   - User premium status updated in real-time
   - Premium features automatically unlocked
   - Payment history updated

## Backend Requirements

Your backend should handle:

1. **Payment Creation** (`POST /payments`)

   - Validate user authentication
   - Create payment record
   - Generate MoMo payment URL
   - Return payment data and URL

2. **MoMo Webhook** (`POST /webhooks/payment/momo`)

   - Validate MoMo signature
   - Update payment status
   - Upgrade user to premium
   - Send notifications

3. **Payment Queries**
   - Get payment by ID
   - Get user payment history
   - Real-time status updates

## Security Considerations

1. **Authentication**: All payment APIs require JWT token
2. **Validation**: Payment amounts and plans validated on backend
3. **Webhook Security**: MoMo webhooks validated with HMAC signature
4. **State Management**: Payment status synchronized between client and server

## Error Handling

The implementation includes comprehensive error handling:

- Network connectivity issues
- Payment failures
- Invalid payment data
- MoMo redirection errors
- Real-time status updates

## Testing

Use the backend test script to verify:

```bash
bun run scripts/test-momo-payment.ts
```

This implementation provides a complete, production-ready premium subscription system with MoMo payment integration for your Flutter chat application.
