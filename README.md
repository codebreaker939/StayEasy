# StayEasy

A modern hotel booking application built with **Flutter**, **Supabase**, and **Google Gemini**.

StayEasy combines hotel discovery, secure booking, AI-assisted search, season-aware review ranking, 360° room previews, trip management, and a role-based admin portal.

## Features

- Hotel and room discovery
- Destination, date, and guest-based search
- Gemini-powered natural-language AI Search
- Deterministic stay-date-aware review ranking
- AI review insights grounded in real reviews
- Interactive 360° room previews
- Supabase Authentication
- Secure server-side booking and cancellation
- My Trips
- Role-based Admin Portal
- Responsive Flutter UI for mobile, tablet, and desktop

## AI Search

StayEasy lets users describe their trip naturally.

Example prompts:

```text
Find me a hotel in Mumbai for two people in October.
```

```text
Show me a stay in Goa for two guests under ₹8,000 with Wi-Fi.
```

The flow is:

```text
Flutter
  ↓
Supabase Edge Function
  ↓
Google Gemini
  ↓
Validated structured filters
  ↓
StayEasy repository
  ↓
Real hotel results
```

Gemini interprets the user's intent, while actual hotel matching is performed using StayEasy's application data.

## Season-Aware Reviews

StayEasy ranks reviews using deterministic Dart logic.

The user's intended stay period is considered when calculating review relevance, so reviews from a similar month or season can be prioritized when other factors are comparable.

Gemini does **not** control review ordering.

## AI Review Insights

Gemini can summarize selected review evidence through Supabase Edge Functions.

Returned review source IDs are validated against the supplied evidence. If there is not enough relevant evidence, StayEasy returns an `insufficient_evidence` state instead of forcing a generated summary.

## 360° Room Preview

StayEasy includes an interactive spherical room tour with:

- Drag navigation
- Zoom
- Hotspots
- Bedroom, Bathroom, and Balcony views
- Fullscreen mode

## Secure Booking

Booking is handled through a server-side Supabase PostgreSQL RPC.

The backend validates:

- Authenticated user
- Room status
- Guest capacity
- Stay dates
- Availability
- Inventory
- Pricing
- Taxes
- Discounts

The authoritative booking total is calculated on the server, and inventory is updated atomically.

## My Trips

Authenticated users can view their own bookings in the **My Trips** section.

Access is protected using PostgreSQL privileges and Supabase Row Level Security.

## Admin Portal

StayEasy includes an admin portal at:

```text
/admin
```

Admin features include:

- Dashboard
- Hotels
- Rooms
- Availability
- Bookings
- Reviews

Access is protected using role-based authorization.

## Tech Stack

### Frontend

- Flutter
- Dart
- Material 3
- Riverpod
- go_router

### Backend

- Supabase
- PostgreSQL
- Supabase Authentication
- Row Level Security
- PostgreSQL RPCs
- Supabase Edge Functions

### AI

- Google Gemini API
- Structured AI outputs
- Server-side validation

### 360° Experience

- Panorama Viewer
- Equirectangular panorama images
- Spherical hotspots

## Architecture

```text
Flutter UI
    ↓
Riverpod
    ↓
Repository Layer
    ↓
Supabase
 ┌──────────────┬──────────────┬────────────────┐
 │ PostgreSQL   │ RPC          │ Edge Functions │
 │ + RLS        │ Booking      │ + Gemini       │
 └──────────────┴──────────────┴────────────────┘
```

## Project Structure

```text
lib/
├── core/
├── features/
│   ├── auth/
│   ├── explore/
│   ├── search/
│   ├── hotel/
│   ├── room/
│   ├── reviews/
│   ├── booking/
│   ├── trips/
│   └── admin/
└── main.dart

supabase/
├── functions/
│   ├── ai-search/
│   ├── ai-review-insights/
│   └── _shared/
└── migrations/
```

## Environment Setup

Create:

```text
config/dev.json
```

Example:

```json
{
  "SUPABASE_URL": "YOUR_SUPABASE_URL",
  "SUPABASE_PUBLISHABLE_KEY": "YOUR_SUPABASE_PUBLISHABLE_KEY"
}
```

Do not commit real credentials.

The Gemini API key should be stored only in Supabase Edge Function Secrets:

```text
GEMINI_API_KEY
```

## Run the Project

Install dependencies:

```bash
flutter pub get
```

Run web:

```bash
flutter run -d web-server \
  --web-port 8081 \
  --dart-define-from-file=config/dev.json
```

Open:

```text
http://localhost:8081
```

Admin Portal:

```text
http://localhost:8081/admin
```

## Testing

```bash
flutter analyze
flutter test
dart format .
```

Build web:

```bash
flutter build web \
  --dart-define-from-file=config/dev.json
```

## Security

StayEasy follows a server-authoritative security model:

- AI secrets are never stored in Flutter
- User bookings are protected with RLS
- Booking totals and inventory changes are handled server-side
- Admin access is role-based
- AI does not control critical booking or ranking logic

## Future Improvements

- Real payment gateway integration
- Push notifications
- Hotel-owner onboarding
- Property-specific 360° captures
- Personalized recommendations
- Email booking confirmations
- Production monitoring

## Academic Project

**Project:** StayEasy  
**Developer:** Aniket Rai  
**Program:** B.Tech Computer Science & Engineering  
**Batch:** 2024–2028  
**Semester:** 5

## License

This project was developed for academic and educational purposes.

Third-party assets and libraries remain subject to their respective licenses.
