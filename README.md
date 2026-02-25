# 👑 Royal Star Boys — Private Community Fund Management System

A production-ready full-stack web application for managing a single private financial group. Members contribute monthly, borrow from the shared fund with simple interest, and all activity is tracked in real-time dashboards.

---

## 🚀 Tech Stack

| Layer      | Technology |
|------------|-----------|
| Frontend   | React 18 + Vite, React Router, Recharts, Socket.io-client |
| Backend    | Node.js + Express, Socket.io, JWT, bcrypt, Zod, Winston |
| Database   | MySQL 8 with FK constraints + transaction-safe fund updates |
| DevOps     | Docker Compose, Nginx (SPA proxy) |

---

## 📁 Project Structure

```
ROYAL/
├── backend/           # Node.js API (MVC)
│   └── src/
│       ├── config/    # DB + Socket.io
│       ├── controllers/
│       ├── middleware/ # auth, authorize, validate, errorHandler
│       ├── routes/
│       ├── services/  # creditScore, loanService, groupFundService
│       └── utils/
├── frontend/          # React + Vite
│   └── src/
│       ├── context/   # Auth + Socket providers
│       ├── pages/     # 7 admin pages + 4 member pages + login
│       └── components/
├── database/
│   └── schema.sql     # All tables with FK constraints
└── docker-compose.yml
```

---

## ⚡ Quick Start — Local Development

### Prerequisites
- Node.js 18+
- MySQL 8 running locally

### 1. Database Setup

```bash
mysql -u root -p < database/schema.sql
```

### 2. Backend

```bash
cd backend
cp .env.example .env         # Fill in DB credentials and JWT secret
npm install
npm run dev                  # Starts on http://localhost:5000
```

On first start, an admin account is **auto-seeded** using values from `.env`:
- Email: `admin@royalstarboys.com`
- Password: `Admin@1234`

### 3. Frontend

```bash
cd frontend
npm install
npm run dev                  # Starts on http://localhost:5173
```

---

## 🐳 Docker Deployment

```bash
# Copy and edit environment variables
cp backend/.env.example .env

# Start all services
docker-compose up --build -d
```

Access the app at: **http://localhost:5173**

API docs (Swagger): **http://localhost:5000/api/docs**

---

## ☁️ Cloud Deployment

### Backend → Render / Railway

1. Push `backend/` to a repo
2. Set environment variables (see `.env.example`)
3. Build command: `npm install`
4. Start command: `node src/server.js`

### Frontend → Vercel

1. Push `frontend/` to a repo
2. Set `VITE_API_URL=https://your-backend.onrender.com/api`
3. Set `VITE_SOCKET_URL=https://your-backend.onrender.com`
4. Build command: `npm run build`, output: `dist`

### Database → Aiven / PlanetScale / TiDB

1. Create a MySQL instance in the cloud
2. Run `database/schema.sql` to create tables
3. Update `DB_*` env vars in your backend deployment

---

## 🔐 Default Admin Login

| Field    | Value |
|----------|-------|
| Email    | `admin@royalstarboys.com` |
| Password | `Admin@1234` |

> ⚠️ Change the admin password immediately after first login in production.

---

## 💡 Core Modules

| Module | Description |
|--------|-------------|
| **Auth** | JWT login, role-based access (admin/member) |
| **Group Config** | Single-row table: group name, subscription, interest rate |
| **Members**  | Admin CRUD, credit score per member |
| **Contributions** | Monthly payments, auto fund updates |
| **Loans** | SI formula `(P×R×T)/100`, approve/reject flow |
| **Repayments** | Proportional principal+interest splitting, auto-close |
| **Credit Score** | 300–900 range, auto-updated on key events |
| **Ledger** | Immutable transaction history with pagination |
| **Real-time** | Socket.io broadcasts on contribution/loan/repayment events |

---

## 📡 API Reference

Swagger docs available at `/api/docs` when server is running.

Key endpoints:

```
POST /api/auth/login
GET  /api/auth/me
GET  /api/dashboard/admin
GET  /api/dashboard/member
GET  /api/members
POST /api/members
GET  /api/contributions
POST /api/contributions
GET  /api/loans
POST /api/loans          (member — request)
POST /api/loans/:id/approve  (admin)
GET  /api/repayments
POST /api/repayments
GET  /api/transactions
GET  /api/group
PUT  /api/group          (admin)
```

---

## 🏦 Simple Interest Formula

```
SI = (Principal × Rate × Time) / 100
Total Payable = Principal + SI
```

Interest earned from repayments is automatically added back to the group fund.

---

## 🧮 Credit Score Rules

| Event | Change |
|-------|--------|
| On-time monthly contribution | +10 |
| Missed contribution | −15 |
| Early full loan repayment | +20 |
| Delayed repayment | −25 |

Range: 300 (Poor) → 900 (Excellent). Starting score: **500**
