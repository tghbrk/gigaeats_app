# Product Requirements Document: GigaEats

**Version:** 2.0  
**Date:** December 2024  
**Author:** GigaEats Development Team  
**Status:** In Development - Phase 2 Active

## Table of Contents

1. [Introduction & Core Product Overview](#introduction--core-product-overview)
2. [Product Goals](#product-goals)
3. [Key Stakeholders & User Personas](#key-stakeholders--user-personas)
   - 3.1 [Sales Agents](#31-sales-agents)
   - 3.2 [Food Vendors](#32-food-vendors)
   - 3.3 [End Customers (Bulk Buyers)](#33-end-customers-bulk-buyers)
4. [Core Features](#core-features)
   - 4.1 [Sales Agent Dashboard](#41-sales-agent-dashboard)
   - 4.2 [Vendor Portal](#42-vendor-portal)
   - 4.3 [End Customer Interface](#43-end-customer-interface)
   - 4.4 [Delivery Integration & Logistics](#44-delivery-integration--logistics)
   - 4.5 [Platform Administration](#45-platform-administration)
5. [User Journeys](#user-journeys)
   - 5.1 [Sales Agent: New Order Creation](#51-sales-agent-new-order-creation)
   - 5.2 [Food Vendor: Order Fulfillment](#52-food-vendor-order-fulfillment)
   - 5.3 [End Customer: Placing a Bulk Order (via Sales Agent)](#53-end-customer-placing-a-bulk-order-via-sales-agent)
   - 5.4 [End Customer: Placing a Direct Bulk Order (Future Scope)](#54-end-customer-placing-a-direct-bulk-order-future-scope)
6. [Technical Requirements](#technical-requirements)
   - 6.1 [System Architecture](#61-system-architecture)
   - 6.2 [Performance & Scalability](#62-performance--scalability)
   - 6.3 [Security](#63-security)
   - 6.4 [Data Management & Analytics](#64-data-management--analytics)
   - 6.5 [API Integrations](#65-api-integrations)
   - 6.6 [Multi-language Support](#66-multi-language-support)
   - 6.7 [Malaysian Business Compliance](#67-malaysian-business-compliance)
7. [Current Implementation Status](#current-implementation-status)
8. [Business Requirements](#business-requirements)
   - 7.1 [Commission Calculation & Payout System](#71-commission-calculation--payout-system)
   - 7.2 [Payment Integration](#72-payment-integration)
   - 7.3 [Customer Support](#73-customer-support)
   - 7.4 [Reporting & Analytics](#74-reporting--analytics)
9. [Brand Positioning](#brand-positioning)
10. [Monetization Strategy](#monetization-strategy)
11. [Success Metrics (KPIs)](#success-metrics-kpis)
12. [Competitive Analysis](#competitive-analysis)
13. [Implementation Timeline](#implementation-timeline)
14. [Risk Assessment & Mitigation](#risk-assessment--mitigation)
15. [Future Considerations / Roadmap](#future-considerations--roadmap)

## 1. Introduction & Core Product Overview

GigaEats is a three-sided B2B2C marketplace designed to revolutionize bulk food ordering in Malaysia. It connects Sales Agents, Food Vendors, and Bulk Food Buyers (corporates, event organizers, caterers, institutions) on a unified, efficient, and scalable platform.

**Sales Agents** act as intermediaries, leveraging their networks and expertise to aggregate large-volume food orders. They earn commissions from vendors for orders facilitated through the platform.

**Food Vendors** (restaurants, caterers, cloud kitchens, food manufacturers) gain access to a wider market for bulk orders, streamline their operations, and manage large-scale catering requests efficiently.

**Bulk Food Buyers** benefit from a curated selection of vendors, competitive pricing, simplified ordering processes for large quantities, and reliable delivery.

GigaEats aims to be the leading platform for "giga" scale food requirements, emphasizing reliability, variety, and technological sophistication. The platform will generate revenue primarily through a 7% transaction fee levied on food vendors for successful orders.

## 2. Product Goals

### Primary Goals

- Establish GigaEats as the preferred platform for bulk food ordering in Malaysia within 3 years
- Achieve a significant gross merchandise volume (GMV) by streamlining the B2B food procurement process
- Empower sales agents with tools to effectively manage and grow their client base
- Provide food vendors with a reliable channel for large orders and tools for efficient fulfillment
- Offer bulk buyers a convenient, transparent, and cost-effective solution for their catering needs

### Secondary Goals

- Foster a strong community among sales agents and vendors
- Continuously innovate and improve the platform based on user feedback and market trends
- Expand service offerings and geographic reach within Malaysia

## 3. Key Stakeholders & User Personas

### 3.1 Sales Agents

**Description:** Independent contractors, freelance event planners, corporate administrative staff, catering sales coordinators, or individuals with strong networks in organizations requiring bulk food. They are motivated by commission and the flexibility to manage their own sales efforts.

**Needs & Pain Points:**
- Access to a wide variety of reliable food vendors
- Efficient tools for creating and managing bulk orders
- Transparent commission tracking and timely payouts
- CRM-like features to manage client relationships and order history
- Communication tools to interact with clients and vendors
- Difficulty in finding and coordinating with multiple vendors for large, diverse orders
- Lack of standardized processes for order placement and tracking

**Persona Example: "Ahmad, the Freelance Event Coordinator"**
- **Age:** 35
- **Occupation:** Freelance Event Planner
- **Tech Savviness:** High
- **Goals:** Find reliable, diverse catering options for his corporate clients, streamline the ordering process, maximize his commission earnings
- **Frustrations:** Spending too much time calling individual caterers, negotiating prices, and managing logistics for large events. Needs a centralized platform

### 3.2 Food Vendors

**Description:** Restaurants (with catering capacity), dedicated caterers, cloud kitchens, and food manufacturers capable of handling large-volume orders. They seek to increase their sales channels and optimize their kitchen operations for bulk production.

**Needs & Pain Points:**
- Access to a consistent stream of large orders
- Tools for easy menu management, including special bulk pricing and customization options
- Real-time inventory management to prevent over-commitment
- Efficient order fulfillment and kitchen production planning
- Clear visibility on order details, delivery schedules, and payment reconciliation
- Analytics to understand demand, popular items, and sales performance
- High commission rates from other platforms or traditional agents
- Managing last-minute changes or large, complex orders

**Persona Example: "Priya, Owner of 'Curry House Catering'"**
- **Age:** 42
- **Occupation:** Owner & Head Chef of a medium-sized catering business
- **Tech Savviness:** Medium
- **Goals:** Increase her catering business's reach, secure more corporate clients, manage bulk orders more efficiently, reduce food wastage
- **Frustrations:** Difficulty in marketing her bulk services, managing fluctuating demand, coordinating deliveries for multiple large orders simultaneously

### 3.3 End Customers (Bulk Buyers)

**Description:** Corporations (for staff meals, events), event management companies, wedding planners, schools, hospitals, government agencies, and any organization requiring food in large quantities.

**Needs & Pain Points:**
- Reliable and timely delivery of quality food
- Variety of cuisine options and ability to cater to dietary restrictions
- Competitive and transparent pricing
- Simplified and standardized ordering process
- Ability to manage and track orders, especially for recurring needs
- Professional and trustworthy service
- Finding vendors who can handle very large or specialized orders
- Ensuring food quality and safety for large groups

**Persona Example: "Sarah, Corporate HR Manager"**
- **Age:** 38
- **Occupation:** HR Manager responsible for employee engagement and company events
- **Tech Savviness:** High
- **Goals:** Easily order food for company meetings, training sessions, and annual dinners. Ensure food quality, variety, and adherence to budget
- **Frustrations:** Time-consuming process of sourcing quotes from multiple caterers, inconsistent food quality, managing invoices and payments

## 4. Core Features

### 4.1 Sales Agent Dashboard

**User Registration & Profile Management:**
- Secure sign-up and login
- Profile creation with contact details, experience, and bank information for commission payouts
- KYC (Know Your Customer) process for verification

**Vendor Catalog & Browsing:**
- Searchable and filterable catalog of approved vendors
- View vendor profiles, menus, bulk pricing, MOQs (Minimum Order Quantities), service areas, and ratings/reviews

**Bulk Order Creation & Management:**
- Intuitive interface to create complex bulk orders (multiple items, multiple vendors for a single event if necessary)
- Customization options (e.g., dietary preferences, packaging)
- Ability to request quotes from multiple vendors
- Order tracking (pending, confirmed, preparing, out for delivery, delivered, canceled)
- Order history and re-ordering capabilities

**Customer Relationship Management (CRM Lite):**
- Manage a database of their end customers (corporates, event organizers)
- Track customer order history and preferences
- Store notes and communication logs for each customer

**Commission Tracking & Analytics:**
- Real-time view of earned commissions (pending, approved, paid)
- Detailed breakdown of commission per order
- Payout history and statements
- Basic sales performance analytics (e.g., total sales, top customers, top vendors)

**Communication Tools:**
- In-app messaging with end customers (for clarifications, updates)
- In-app messaging/ticketing with GigaEats support
- Notifications for order updates, new leads (future), and platform announcements

**Quotation Management:**
- Ability to generate and send quotations to end customers
- Track quotation status (sent, viewed, accepted, rejected)

### 4.2 Vendor Portal

**User Registration & Profile Management:**
- Secure sign-up and login for vendor owners/managers
- Detailed profile creation: business name, address, contact, SSM registration, bank details, cuisine types, service areas, operating hours, halal certification (if applicable)
- Onboarding and verification process by GigaEats admin

**Menu & Inventory Management:**
- Create and manage detailed menus specifically for bulk orders (items, descriptions, images, pricing tiers for different quantities)
- Ability to set MOQs, lead times for specific items/order sizes
- Real-time or scheduled inventory updates for key ingredients or dishes to prevent overbooking
- Mark items as available/unavailable
- Support for customizable meal packages

**Order Fulfillment Dashboard:**
- View incoming order requests and confirmed orders
- Accept/reject order requests (with reason)
- Update order status (confirmed, preparing, ready for pickup/delivery)
- Printable order summaries/kitchen dockets
- Manage delivery schedules and assign to in-house fleet or coordinate with Lalamove/pickup

**Capacity Planning Tools:**
- Set daily/weekly maximum order capacity (e.g., number of pax, total order value)
- Calendar view of upcoming orders and kitchen load

**Analytics & Reporting:**
- Sales performance (total revenue, number of orders, average order value)
- Popular items, peak order times
- Customer feedback and ratings
- Commission statements and payout history

**Promotional Tools:**
- Ability to create and manage promotions/discounts for bulk orders visible to sales agents
- Feature new menu items or special packages

**Commission Management:**
- View commission rates and calculations for each order
- Dispute resolution mechanism for commission discrepancies

**Communication Tools:**
- In-app messaging with sales agents regarding specific orders
- In-app messaging/ticketing with GigaEats support
- Notifications for new orders, cancellations, and platform updates

### 4.3 End Customer Interface

**Order Viewing & Tracking (Shared by Sales Agent):**
- Customers receive links or PDF summaries of their orders
- Ability to view order status (if shared by Sales Agent)

**Communication Channel:**
- Means to communicate with their designated Sales Agent for order modifications or queries

**Future Scope: Direct Customer Portal:**
- Self-service order placement for approved corporate accounts
- Saved addresses, payment methods, and order history

### 4.4 Delivery Integration & Logistics

**Lalamove API Integration:**
- Seamless integration for on-demand delivery booking by vendors
- Automated quote generation based on distance and vehicle type
- Real-time delivery tracking for vendors, sales agents, and potentially end customers
- Proof of delivery

**In-House Delivery Fleet Management (for Vendors with own fleet):**
- Option for vendors to mark orders as self-delivered
- Basic tools to assign orders to their own drivers and update delivery status manually

**Pickup Coordination:**
- Support for orders where the end customer or sales agent arranges pickup
- Clear communication of pickup times and location

**Delivery Tracking Visibility:**
- Sales agents and vendors can track the status of deliveries
- Notifications for key delivery milestones (e.g., driver assigned, en route, delivered)

### 4.5 Platform Administration

**User Management:**
- Approve/reject/manage sales agent and vendor accounts
- Manage roles and permissions

**Order Oversight:**
- Monitor all orders on the platform
- Intervene in disputes or issues

**Content Management:**
- Manage platform-wide announcements, FAQs, help guides

**Commission & Payout Management:**
- Oversee commission calculations and manage payout processes
- Handle disputes and adjustments

**Financial Reporting & Analytics:**
- Platform-wide revenue, GMV, transaction volume
- User growth and activity metrics

**System Configuration:**
- Manage platform settings (e.g., commission rates, service fees, supported payment gateways)

**Support Ticket Management:**
- Manage and resolve support requests from all user types

**Vendor Vetting & Onboarding:**
- Tools to manage the vendor application and approval process, including document verification (SSM, Halal certs, F&B licenses)

## 5. User Journeys

### 5.1 Sales Agent: New Order Creation

1. **Login:** Ahmad logs into the GigaEats Sales Agent Dashboard
2. **Client Selection/Creation:** Ahmad selects an existing client (e.g., "TechCorp Sdn Bhd") or adds a new client
3. **Event Details:** Enters event details: date, time, delivery address, number of attendees, budget (optional)
4. **Browse Vendors/Menus:** Ahmad browses vendors, filtering by cuisine type, location, budget, and client preferences. He reviews menus and bulk pricing
5. **Add to Cart:** Selects items from one or more vendors, specifying quantities and any customization notes
6. **Review Order:** Reviews the consolidated order, total estimated cost, and his potential commission
7. **Request Quotation / Place Order:**
   - **Option A (Request Quote):** Submits the order details to selected vendors for a final quotation if prices are variable or customization is complex
   - **Option B (Direct Order):** If prices are fixed and items standard, proceeds to place the order
8. **Vendor Confirmation:** Ahmad receives notifications as vendors confirm (or reject with reason) their part of the order
9. **Client Confirmation:** Ahmad finalizes the order details and confirms with TechCorp, possibly sending a GigaEats-generated quotation
10. **Payment Coordination:** Ahmad coordinates payment from TechCorp (details depend on payment integration chosen)
11. **Track Order:** Monitors order preparation and delivery status via the dashboard
12. **Post-Delivery:** Confirms delivery with the client and ensures satisfaction. Commission is processed

### 5.2 Food Vendor: Order Fulfillment

1. **Notification:** Priya (Curry House Catering) receives a notification for a new order request/confirmed order via the Vendor Portal
2. **Review Order:** Logs in and reviews order details: items, quantities, delivery date/time, special instructions from Sales Agent Ahmad
3. **Check Capacity/Inventory:** Verifies kitchen capacity and ingredient availability
4. **Accept/Reject Order:**
   - **Accepts:** Confirms the order. The status updates on Ahmad's dashboard
   - **Rejects:** Provides a reason (e.g., insufficient capacity, item unavailable)
5. **Prepare Order:** Kitchen staff prepares the food according to the schedule
6. **Update Status:** Priya updates the order status to "Preparing," then "Ready for Delivery/Pickup"
7. **Arrange Delivery:**
   - **Lalamove:** Uses the integrated Lalamove feature to book a delivery. Tracking info is updated
   - **In-House:** Assigns to her own driver and updates status manually
   - **Pickup:** Coordinates pickup time with Ahmad or the end customer
8. **Order Delivered:** Confirms delivery completion
9. **Payment & Commission:** GigaEats processes the payment from the order and deducts the commission. Priya sees the net amount in her portal

### 5.3 End Customer: Placing a Bulk Order (via Sales Agent)

1. **Initial Contact:** Sarah (HR Manager) contacts Ahmad (Sales Agent) with her company's event catering needs
2. **Requirement Discussion:** Sarah provides details: event type, date, number of pax, budget, dietary needs, cuisine preferences
3. **Receive Options/Quote:** Ahmad uses GigaEats to find suitable vendors and prepares a proposal/quotation for Sarah
4. **Review & Confirm:** Sarah reviews the proposal, discusses any changes with Ahmad, and gives approval
5. **Payment:** Sarah arranges payment through her company's finance department based on the invoice provided by Ahmad (facilitated by GigaEats)
6. **Receive Updates:** Ahmad keeps Sarah informed about the order status
7. **Food Delivery:** Food is delivered to the corporate event as scheduled
8. **Feedback:** Sarah provides feedback to Ahmad about the food and service

### 5.4 End Customer: Placing a Direct Bulk Order (Future Scope)

1. **Login:** Approved corporate user logs into the GigaEats customer portal
2. **Browse/Search:** Searches for vendors or specific menu items for their event
3. **Order Creation:** Adds items to cart, specifies delivery details
4. **Checkout & Payment:** Makes payment via approved corporate methods (e.g., invoicing, pre-approved credit)
5. **Track Order:** Monitors order status directly on the platform

## 6. Technical Requirements

### 6.1 System Architecture

**Frontend:**
- **Flutter Cross-Platform App** - Single codebase for iOS, Android, and Web
- **Material Design 3** - Modern UI with adaptive theming
- **Progressive Web App (PWA)** - Web deployment with app-like experience
- **Responsive Design** - Optimized for mobile, tablet, and desktop

**Backend & Database (Supabase):**
- **Supabase** - Backend-as-a-Service platform (PostgreSQL + Auth + Storage + Realtime)
- **PostgreSQL Database** - Primary database with Row Level Security (RLS)
- **Supabase Auth** - JWT-based authentication with role management
- **Supabase Storage** - File uploads for images and documents
- **Supabase Realtime** - Live updates for orders and notifications
- **Supabase Edge Functions** - Serverless functions for complex business logic

**Authentication & Security:**
- **Pure Supabase Authentication** - Migrated from Firebase Auth hybrid approach
- **Role-Based Access Control** - Admin, Sales Agent, Vendor, Customer roles
- **Row Level Security (RLS)** - Database-level security policies
- **Malaysian Phone Verification** - SMS OTP for +60 numbers
- **JWT Token Management** - Automatic refresh and secure storage

**State Management & Architecture:**
- **Riverpod** - State management and dependency injection
- **Clean Architecture** - Domain, data, and presentation layers
- **Repository Pattern** - Data access abstraction
- **Either Pattern** - Robust error handling and result types

### 6.2 Performance & Scalability

**Supabase Infrastructure:**
- **Automatic Scaling** - Supabase handles database scaling and connection pooling
- **Global CDN** - Built-in content delivery network for static assets
- **High Availability** - 99.9% uptime SLA with automatic failover
- **Connection Pooling** - Efficient database connection management

**Flutter Performance:**
- **Lazy Loading** - Vendor catalogs and large lists load on demand
- **Image Caching** - Optimized image loading with cached_network_image
- **Efficient Rendering** - Pagination and virtual scrolling for large datasets
- **Background Sync** - Offline capability with local data caching

**Performance Targets:**
- **App Startup Time:** < 3 seconds on average devices
- **Order Creation Flow:** < 30 seconds end-to-end
- **Real-time Updates:** < 2 seconds latency
- **API Response Time:** < 500ms for most operations
- **Concurrent Users:** 1000+ supported (Supabase Pro plan)

**Database Optimization:**
- **Indexed Queries** - Proper indexing on frequently accessed columns
- **RLS Performance** - Optimized Row Level Security policies
- **Query Optimization** - Efficient joins and data fetching patterns
- **Caching Strategy** - Local storage with Hive for offline data

### 6.3 Security

- **Data Encryption:** SSL/TLS for data in transit, Encryption at rest for sensitive data (e.g., user PII, payment information)
- **Authentication & Authorization:** Secure password policies, multi-factor authentication (MFA) option, Role-based access control (RBAC) for different user types and admin functions
- **Input Validation & Sanitization:** Prevent common web vulnerabilities (XSS, SQL injection)
- **Regular Security Audits & Penetration Testing**
- **Compliance with PDPA (Personal Data Protection Act) Malaysia**

### 6.4 Data Management & Analytics

- **Centralized Data Warehouse:** For collecting data from various microservices for analytics and reporting
- **Real-time Data Processing:** For dashboards and immediate insights (e.g., order tracking, inventory levels)
- **Data Backup & Recovery:** Regular automated backups and a clear disaster recovery plan

### 6.5 API Integrations

- **Payment Gateway:** FPX (via major Malaysian bank gateways like Billplz, iPay88, Stripe Malaysia), e-wallets (GrabPay, Touch 'n Go eWallet, Boost), credit/debit cards
- **Delivery Service:** Lalamove API (or similar providers like GrabExpress)
- **Communication:** SMS gateway (for OTPs, notifications), Email service (SendGrid, Mailgun)
- **Accounting Software (Future):** Integration with Xero, QuickBooks for vendors

### 6.6 Multi-language Support

- **Platform Languages:** Bahasa Malaysia, English, Chinese (Simplified)
- **User Interface:** All UI elements, labels, notifications, and email templates must be translatable
- **User-Generated Content:** Allow users to input information (e.g., menu descriptions) in their preferred language, but encourage primary languages for broader reach
- **Language Selection:** Users should be able to set their preferred language

### 6.7 Malaysian Business Compliance

**SST (Sales & Service Tax):**
- System must be able to correctly calculate and apply SST where applicable (based on vendor registration status)
- Vendors should be able to input their SST registration number
- Invoices and receipts must clearly show SST amounts

**Business Registration:**
- Vendors must provide valid SSM (Suruhanjaya Syarikat Malaysia) registration details during onboarding
- Mechanism for GigaEats admin to verify these details

**Halal Certification:**
- Vendors can indicate Halal status and upload supporting documents
- Search filter for Halal-certified vendors

**Food Safety Standards:** While GigaEats is a platform, promote awareness and potentially require vendors to declare adherence to local food safety guidelines

## 7. Current Implementation Status (December 2024)

### ✅ Phase 1 Completed Features (Foundation)

**Authentication & Core Infrastructure:**
- ✅ **Pure Supabase Authentication System** - Migrated from Firebase Auth to Supabase Auth
- ✅ **Role-Based Access Control** - Admin, Sales Agent, Vendor, Customer roles
- ✅ **Flutter App Architecture** - Clean architecture with Riverpod state management
- ✅ **Material Design 3 Theme** - Modern UI with dark/light theme support
- ✅ **Multi-language Support** - English, Bahasa Malaysia, Chinese structure
- ✅ **Cross-Platform Support** - Android, iOS, Web deployment ready

**User Management:**
- ✅ **User Registration/Login** - Email/password with email verification
- ✅ **Phone Verification** - Malaysian phone numbers (+60) with SMS OTP
- ✅ **Profile Management** - User profiles with role-specific data
- ✅ **Password Reset** - Secure password recovery flow

**Core Data Models:**
- ✅ **User Models** - Complete user, vendor, customer, admin models
- ✅ **Order Management** - Order lifecycle with status tracking
- ✅ **Product/Menu Models** - Vendor menu items with bulk pricing
- ✅ **Commission System** - Sales agent commission calculation

### 🔄 Phase 2 Active Development (Current Focus)

**Sales Agent Dashboard:**
- 🔄 **Vendor Browsing** - Search, filter, and browse vendor catalogs
- 🔄 **Order Creation Flow** - Multi-vendor cart and order placement
- 🔄 **Customer Management** - CRM-lite features for client management
- 🔄 **Commission Tracking** - Real-time earnings and payout tracking

**Vendor Portal:**
- 🔄 **Menu Management** - CRUD operations for menu items and pricing
- 🔄 **Order Fulfillment** - Accept/reject orders, status updates
- 🔄 **Analytics Dashboard** - Basic sales performance metrics
- 🔄 **Profile Management** - Business details and certifications

**Order Management System:**
- 🔄 **Order Workflow** - Complete order lifecycle management
- 🔄 **Status Tracking** - Real-time order status updates
- 🔄 **Delivery Integration** - Preparation for Lalamove API integration
- 🔄 **Payment Preparation** - Foundation for payment gateway integration

### 📋 Phase 3 Planned Features (Next Quarter)

**Advanced Features:**
- 📋 **Payment Integration** - Malaysian payment gateways (FPX, e-wallets)
- 📋 **Lalamove Integration** - Automated delivery booking and tracking
- 📋 **Push Notifications** - Real-time order and system notifications
- 📋 **Advanced Analytics** - Comprehensive reporting and insights
- 📋 **Promotional Tools** - Vendor promotions and discount management

**Platform Enhancements:**
- 📋 **Admin Panel** - Complete platform administration tools
- 📋 **Customer Portal** - Direct customer ordering interface
- 📋 **API Documentation** - Public API for third-party integrations
- 📋 **Mobile Optimization** - Enhanced mobile user experience

## 8. Business Requirements

### 8.1 Commission Calculation & Payout System

**Flexible Commission Structure:**
- Default 7% transaction fee from vendors on the value of food items (excluding delivery fees, SST)
- Ability for admin to set different commission rates for specific vendors or promotions (future)

**Automated Calculation:** Real-time or batch calculation of commissions upon order completion

**Clear Statements:** Sales agents and vendors receive detailed statements of orders, gross amounts, commissions earned/deducted, and net payouts

**Payout Schedule:** Define a regular payout schedule (e.g., weekly, bi-weekly) via bank transfer

**Dispute Resolution:** Mechanism for agents and vendors to raise queries or disputes regarding commissions

### 8.2 Payment Integration

**For End Customers (via Sales Agent or direct):**
- **FPX (Financial Process Exchange):** Essential for Malaysian market, direct bank transfers
- **E-wallets:** GrabPay, Touch 'n Go eWallet, Boost
- **Credit/Debit Cards:** Visa, Mastercard
- **Corporate Invoicing:** Option for approved corporate clients to pay via invoice with defined payment terms (e.g., NET 30). Requires credit control process

**Payouts to Vendors & Sales Agents:**
- Direct bank transfer (DuitNow, IBG) to Malaysian bank accounts

**Secure Payment Processing:** PCI DSS compliance (if handling card data directly, otherwise rely on compliant gateways)

**Refund & Cancellation Handling:** Clear process for managing refunds and cancellations, including impact on commissions

### 8.3 Customer Support

**Multi-channel Support:**
- In-app messaging/ticketing system
- Email support
- Phone support (during business hours)
- FAQ / Knowledge Base for self-service

**Tiered Support:** For different user types and issue complexities

**SLA for Response Times:** Define target response and resolution times

### 8.4 Reporting & Analytics

- **For GigaEats Admin:** Comprehensive dashboards on platform performance, user acquisition, GMV, revenue, top-performing agents/vendors, regional performance
- **For Sales Agents:** Sales performance, commission earnings, client activity
- **For Vendors:** Order volume, revenue, popular items, customer feedback

## 9. Brand Positioning

**"GigaEats: Your Partner for Giga Food Orders."**

**Core Message:** Emphasize capability to handle large-scale, complex food orders with ease and reliability

**Brand Identity:**
- **Modern & Tech-Forward:** Clean, intuitive UI/UX. Professional and efficient
- **Trustworthy & Reliable:** Focus on quality vendors, timely delivery, and transparent processes  
- **Malaysian-Centric:** Understanding local needs, languages, and business practices

**Tone of Voice:** Professional, supportive, efficient, innovative

**Visuals:** High-quality imagery of diverse food, professional settings, and collaborative interactions

## 10. Monetization Strategy

**Primary Revenue Stream: Vendor Commission**
- 7% transaction fee charged to food vendors on the total value of food items (excluding delivery fees paid to third parties like Lalamove, and SST collected on behalf of the government)

**Potential Future Revenue Streams:**
- **Premium Vendor Subscriptions:** For enhanced visibility, advanced analytics, or lower commission rates
- **Featured Listings:** Vendors pay for prominent placement in search results
- **Value-Added Services for Sales Agents:** Premium tools, lead generation
- **Advertising:** Relevant ads from food suppliers, packaging companies, etc.
- **Data Monetization (Aggregated & Anonymized):** Market insights for the F&B industry

## 11. Success Metrics (KPIs)

**Platform Growth:**
- Number of Active Sales Agents
- Number of Active Food Vendors
- Number of Registered End Customers (Bulk Buyers)
- Gross Merchandise Volume (GMV)
- Number of Orders Processed
- Average Order Value (AOV)

**User Engagement & Satisfaction:**
- **Sales Agent:** Order conversion rate, repeat client rate, commission earned
- **Vendor:** Order acceptance rate, fulfillment rate, ratings/reviews
- **End Customer:** Repeat order rate, customer satisfaction scores (CSAT/NPS)
- **Platform:** User activity rates (daily/monthly active users), feature adoption rates

**Financial Performance:**
- Total Revenue
- Net Revenue (after payouts)
- Customer Acquisition Cost (CAC)
- Lifetime Value (LTV) of users

**Operational Efficiency:**
- Order fulfillment time
- Delivery success rate
- Customer support ticket resolution time

## 12. Competitive Analysis

**Direct Competitors (Malaysia):**
- Existing B2B Caterers/Platforms: (e.g., FoodPanda for Business, GrabFood for Business - if they have strong bulk offerings, local catering marketplaces). Analyze their strengths, weaknesses, pricing, and market share
- Traditional Catering Agents/Brokers: Offline players. GigaEats offers a tech-enabled, more efficient alternative

**Indirect Competitors:**
- Individual Restaurants/Caterers with direct sales teams
- DIY solutions by corporates (staff ordering directly)

**GigaEats Differentiators:**
- **Three-sided marketplace model:** Empowering sales agents as a key channel
- **Focus on "Giga" scale:** Specialized tools and processes for very large orders
- **Technology-driven efficiency:** Streamlined ordering, tracking, and management
- **Comprehensive vendor network:** Wide variety and curated quality
- **Localized for Malaysia:** Language, payments, compliance

## 13. Implementation Timeline

### ✅ Phase 1: Foundation & MVP (COMPLETED - 6 months)
**Status: COMPLETED (December 2024)**

**Completed Core Functionality:**
- ✅ **Authentication System** - Pure Supabase Auth with role-based access
- ✅ **Flutter App Architecture** - Clean architecture with Riverpod state management
- ✅ **User Management** - Registration, login, profile management for all user types
- ✅ **Database Schema** - Complete data models for users, vendors, orders, products
- ✅ **Cross-Platform Support** - iOS, Android, an