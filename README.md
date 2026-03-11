# Kigali City Services & Places Directory

A Flutter app that helps you find hospitals, restaurants, schools, banks, and all kinds of services across Kigali. Built with Firebase and Provider.

---

## What you can do

**Browse & Search**
- View all services in one place
- Search by name or filter by category
- Real-time updates as new listings are added

**Map It**
- See services on a map with markers
- Get directions with Google Maps integration
- Find what's near you

**Manage Listings**
- Add your own service or place
- Edit listings you created
- Delete what you no longer need

**Profile**
- Create an account with email
- Manage your profile
- Control notification settings

---

## Tech Stack

- Flutter — UI framework
- Firebase Auth — user authentication
- Cloud Firestore — database
- Provider — state management
- flutter_map — mapping
- geolocator — GPS location

---

## Project Structure

```
lib/
  ├── models/      → Data classes
  ├── services/    → Firebase logic
  ├── providers/   → State management
  └── screens/     → UI screens
```

Simple flow: Firestore → Services → Providers → UI

---

## Database Schema

**users**
- uid, email, displayName
- profile info (district, sector, cell)
- notification preferences

**services**
- name, category, address
- phone, website, description
- coordinates (lat, lng)
- who created it & when

---

## Quick Start

### 1. Setup Firebase

Go to Firebase Console and:
- Create a new project
- Enable Email/Password auth
- Create a Cloud Firestore database
- Run `flutterfire configure`

### 2. Install & Run

```bash
flutter pub get
flutter run
```

### 3. Test It

- Sign up with email
- Verify email
- Create a listing
- View on map

---

## Screens

| Tab | What it does |
|-----|--------------|
| Directory | Browse all services, search, filter |
| My Listings | Your services, edit/delete them |
| Map | See everything on a map |
| Settings | Profile, notifications, logout |

---

## Security

- Email verification required
- Users can only edit their own listings
- Firestore rules enforce ownership
- Authenticated requests only

---

## Features

- Color-coded categories
- GPS-powered map view
- Real-time updates
- Mobile-first design
- Smart search & filtering
- Navigate with Google Maps

---

## Documentation

Check these files for more info:
- QUICK_START.md — setup guide
- CHECKLIST.md — testing checklist
- ARCHITECTURE.md — how it's built
- IMPLEMENTATION_GUIDE.md — detailed docs

---

## About

This is a learning project built for the ALU Mobile Development assignment. It's production-ready with clean code, proper architecture, and full documentation.

Made to help Kigali residents find what they need. Easy to use. Fast. Reliable.

---

Made with Flutter
