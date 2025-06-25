# ⚙️ Feature-Specific Documentation

This folder contains deep-dive documents that explain the design and workflow of specific, complex features.

## Documents in this category:

### Order Management System
- **`ORDER_MANAGEMENT_SYSTEM.md`** - Comprehensive documentation of the order management system, including database design and business logic
- **`order-workflow.md`** - Detailed explanation of the complete lifecycle of an order from creation to completion

### Delivery Proof System
- **`DELIVERY_PROOF_SYSTEM.md`** - Complete documentation for the Proof of Delivery system, including features and architecture
- **`DELIVERY_PROOF_API_REFERENCE.md`** - Technical API reference for the Delivery Proof system endpoints and data structures

### Marketplace Wallet System
- **`MARKETPLACE_WALLET_MASTER_GUIDE.md`** - Comprehensive system overview and integration guide for the multi-party payment system
- **`MARKETPLACE_PAYMENT_SYSTEM.md`** - Core payment system architecture and workflows
- **`MARKETPLACE_EDGE_FUNCTIONS.md`** - API endpoints and Edge Functions documentation
- **`MARKETPLACE_REPOSITORY_SERVICE_LAYER.md`** - Service architecture and repository patterns
- **`MARKETPLACE_RIVERPOD_PROVIDERS.md`** - State management and provider implementation
- **`MARKETPLACE_WALLET_UI_COMPONENTS.md`** - User interface components and role-specific screens
- **`MARKETPLACE_SECURITY_COMPLIANCE.md`** - Security implementation and Malaysian compliance
- **`MARKETPLACE_PAYMENT_TESTING_STRATEGY.md`** - Comprehensive testing approach and strategies
- **`MARKETPLACE_WALLET_USER_GUIDES.md`** - Role-specific user guides for all stakeholders
- **`MARKETPLACE_WALLET_TROUBLESHOOTING.md`** - Common issues and resolution procedures
- **`MARKETPLACE_WALLET_OPERATIONS_GUIDE.md`** - Ongoing operations and maintenance procedures

## Purpose

These documents provide:
- In-depth technical specifications for complex features
- Business logic and workflow explanations
- API references and integration guides
- Database schema and relationship documentation

## Key Features Documented

### Order Management
- Order creation and validation
- Status tracking and updates
- Multi-role order handling (customer, vendor, sales agent, admin)
- Real-time order updates and notifications

### Delivery Proof System
- Photo capture and upload
- GPS location tracking
- Delivery confirmation workflow
- Integration with order management

### Marketplace Wallet System
- Multi-party payment processing and escrow management
- Automated commission distribution across stakeholders
- Secure wallet functionality for all user roles
- Malaysian financial regulations compliance (BNM)
- Real-time transaction tracking and audit trails
- Payout processing and bank integration
- Anti-money laundering (AML) monitoring
- Comprehensive security and encryption measures

## Usage

Refer to these documents when:
- Implementing or modifying complex features
- Understanding business workflows
- Integrating with existing systems
- Troubleshooting feature-specific issues
- Onboarding new developers to specific features
