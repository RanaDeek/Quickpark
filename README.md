# 🚗 Smart Car Parking System

## 📌 Overview
The **Smart Car Parking System** is an IoT-based solution designed to tackle parking congestion in urban areas. The system integrates **ESP32 microcontrollers, infrared (IR) sensors, servo motors, Node.js backend, MongoDB, and a Flutter mobile app** to provide real-time monitoring, automated gate control, and secure digital payments.  

Developed as a **Graduation Project at Birzeit University**, this system aims to improve parking efficiency, reduce fuel consumption, and support smart city initiatives in Palestine.

---

## ✨ Features
- **Real-Time Slot Monitoring** → IR sensors detect vehicle presence and update availability instantly.  
- **Automated Gate Control** → ESP32 + Servo control gates automatically when a slot is available/reserved.  
- **Mobile App (Flutter)** → Allows users to:
  - View available parking slots  
  - Reserve a slot remotely  
  - Manage digital wallet and payments  
  - Receive notifications (reminders, overstay alerts, confirmations)  
- **Secure Payment Options**:
  - In-app wallet system  
  - Manual recharge by agents (no need to link bank account)  
- **Admin Dashboard** → Provides slot analytics, revenue tracking, and misuse detection.  
- **Cloud-Backed Database** → MongoDB + Firebase ensure real-time sync and scalability.  

---

## 🏗️ System Architecture
The project consists of three main components:

### 1. Frontend (Mobile App - Flutter)  
- User onboarding (login/signup)  
- Destination & slot selection  
- Reservation timer & notifications  
- Wallet & payment history  
- Support chatbot  

### 2. Backend (Node.js + Express + MongoDB)  
- User authentication (JWT, OTP reset)  
- Slot reservation & locking system  
- Digital wallet and payment processing  
- REST API + WebSocket communication with ESP32 hardware  

### 3. Hardware (ESP32 + IR + Servo)  
- **ESP32-WROOM-32** microcontroller  
- **Dual IR break-beam sensors** for vehicle detection  
- **SG90 Micro-Servo** for gate barrier control  
- **Power shield** with safe voltage regulation  

---

## 🔧 Installation & Setup

### 1. Clone the repository
```bash
git clone https://github.com/your-username/smart-parking-system.git
cd smart-parking-system
