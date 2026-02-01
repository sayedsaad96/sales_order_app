# Annex Group - Sales Order Management App

> A comprehensive Flutter-based sales order management solution designed for textile and fabric businesses.

---

## 📋 Overview

**Annex Group** is a professional sales order management application built with Flutter, designed specifically for textile, yarn, and fabric businesses. The app streamlines the entire sales workflow from order creation to PDF invoice generation, providing a seamless experience for sales teams and business administrators.

### The Problem It Solves

Managing sales orders, quotations, and invoices manually can be time-consuming and error-prone. This app eliminates paperwork, reduces human errors, and provides instant access to sales data, reports, and customer information—all from a single unified platform.

### Target Users

- 🏢 **Small to Medium Textile Businesses** — Manage daily sales operations
- 👔 **Sales Teams** — Create orders and quotations on the go
- 📊 **Business Administrators** — Analyze sales performance and trends
- 🧶 **Yarn & Fabric Distributors** — Track specialized product orders

---

## ✨ Features

### Core Sales Management
- **Sales Orders** — Create, edit, and manage standard sales orders with multiple line items
- **Yarn Sales Orders** — Specialized orders for yarn products with installment tracking
- **Fabrics & CM Orders** — Dedicated order management for fabrics and cut & make operations
- **Quotations** — Generate professional quotations for potential customers
- **Return Orders** — Handle product returns with full order history

### PDF Generation & Sharing
- **Professional PDF Invoices** — Generate beautifully formatted PDF documents
- **Multi-language Support** — Arabic RTL layout with Cairo font
- **Share & Export** — Share PDFs directly or save locally
- **Authorization Documents** — Generate official authorization letters with company branding

### Customer Management
- **Customer Database** — Store and manage customer information
- **Customer Lookup** — Quick search and selection during order creation
- **Additional Information** — Track extra customer details

### Sales Analytics
- **Visual Charts** — Analyze sales performance with interactive FL Charts
- **Payment Tracking** — Monitor payment methods and outstanding amounts
- **Sales Reports** — Comprehensive reporting by period and category

### Additional Features
- **Price List** — Maintain and share product pricing
- **Data Backup & Restore** — Secure your data with file-based backups
- **Dark Mode** — Full dark/light theme support
- **Offline-First** — Works without internet using local Hive storage
- **Multi-Platform** — Runs on Android, iOS, Windows, macOS, Linux, and Web
- **Auto-Update Notifications** — Stay informed about new app versions

---

## 🛠️ Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform UI framework |
| **Dart** | Programming language |
| **Provider** | State management |
| **Hive** | Local NoSQL database |
| **PDF Package** | PDF document generation |
| **Printing** | PDF preview and printing |
| **FL Chart** | Sales analytics visualization |
| **Intl** | Internationalization & date formatting |
| **Share Plus** | Cross-platform sharing |

---

## 📸 Screenshots

> Add screenshots to the `screenshots/` folder and uncomment the lines below.

<!--
![Splash Screen](screenshots/splash.png)
![Home Dashboard](screenshots/home.png)
![Sales Order Form](screenshots/sales_order.png)
![PDF Invoice Preview](screenshots/pdf_preview.png)
![Sales Analytics](screenshots/analytics.png)
![Customer List](screenshots/customers.png)
![Dark Mode](screenshots/dark_mode.png)
-->

---

## 📁 Project Structure

```
lib/
├── main.dart                 # Application entry point
├── core/                     # Core application modules
│   ├── providers/            # Global state providers
│   ├── services/             # Business logic services
│   │   ├── backup_service.dart
│   │   ├── document_repository.dart
│   │   ├── settings_service.dart
│   │   └── update_notification_service.dart
│   ├── theme/                # App theming (light/dark)
│   ├── utils/                # Utility functions
│   └── widgets/              # Reusable UI components
├── features/                 # Feature modules
│   ├── sales_order/          # Sales order management
│   │   ├── data/             # Models & data sources
│   │   ├── pdf/              # PDF generation logic
│   │   └── presentation/     # UI pages & widgets
│   ├── analysis/             # Sales analytics & charts
│   ├── customer_list/        # Customer management
│   ├── return_order/         # Return order handling
│   ├── authorization/        # Authorization PDF generation
│   ├── user/                 # User profile management
│   ├── settings/             # App settings
│   ├── splash/               # Splash screen
│   └── about/                # About page & resources
└── assets/
    ├── images/               # App images & logo
    ├── fonts/                # Cairo font files
    └── docs/                 # Static documents
```

---

## 🚀 Installation & Run

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.10.1 or higher)
- [Dart SDK](https://dart.dev/get-dart) (included with Flutter)
- Android Studio / VS Code with Flutter extension
- (Optional) Xcode for iOS development

### Steps

1. **Clone the repository**
   ```bash
   git clone https://github.com/sayedsaad96/sales_order_app.git
   cd sales_order_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters** (if needed)
   ```bash
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   # For debug mode
   flutter run

   # For specific platform
   flutter run -d windows
   flutter run -d chrome
   flutter run -d android
   ```

5. **Build for production**
   ```bash
   # Android APK
   flutter build apk --release

   # Windows MSIX
   flutter pub run msix:create

   # iOS
   flutter build ios --release
   ```

---

## ⚙️ Configuration

### No External Configuration Required

This app operates fully offline with local Hive storage. No API keys, Firebase setup, or external services are required for basic functionality.

### Optional Configuration

- **MSIX Packaging** — Update `msix_config` in `pubspec.yaml` for Windows Store deployment
- **App Version** — Modify `version` in `pubspec.yaml` to update app version
- **Certificate** — Replace certificate in `certs/` folder for signed Windows builds

---

## 🔮 Future Improvements

- [ ] Cloud sync with Firebase/Supabase
- [ ] Multi-user authentication & roles
- [ ] Inventory management integration
- [ ] Barcode/QR code scanning
- [ ] Export reports to Excel
- [ ] Email invoices directly to customers
- [ ] Dashboard widgets for quick insights
- [ ] Push notifications for order updates

---

## 👨‍💻 Author

**Sayed Saad**  
*Flutter Developer*

[![GitHub](https://img.shields.io/badge/GitHub-sayedsaad96-181717?style=flat&logo=github)](https://github.com/sayedsaad96)

---

## 📄 License

This project is licensed under the **MIT License**.

```
MIT License

Copyright (c) 2024 Sayed Saad

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

<p align="center">
  Made with ❤️ using Flutter
</p>
