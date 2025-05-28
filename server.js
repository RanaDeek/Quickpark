require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors()); // allows any origin
app.use(express.json());

// MongoDB Connection
mongoose.connect(process.env.MONGO_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to MongoDB Atlas'))
.catch(err => console.error('❌ MongoDB Error:', err));

// Schemas & Models

const userSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  userName: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  wallet: {
    balance: { type: Number, default: 0 },
    lastUpdated: { type: Date, default: Date.now },
  },
});

const User = mongoose.model('User', userSchema);

const chargeLogSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  amount: { type: Number, required: true },
  ownerNumber: { type: String, required: true },
  timestamp: { type: Date, default: Date.now },
  note: String,
});

const ChargeLog = mongoose.model('ChargeLog', chargeLogSchema);

const paymentSchema = new mongoose.Schema({
  userName: String,
  amount: Number,
  description: String,
  date: { type: Date, default: Date.now }
});

const Payment = mongoose.model('Payment', paymentSchema);

const parkingSlotSchema = new mongoose.Schema({
  slotNumber: Number,
  status: { type: String, enum: ['available', 'occupied'], default: 'available' },
  userName: String,
  lastUpdated: Date,
  lockedBy: String,
  lockExpiresAt: Date,
});

const ParkingSlot = mongoose.model('ParkingSlot', parkingSlotSchema);

// Utility function to send OTP email
async function sendOTPEmail(email, otp) {
  const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_PASSWORD,
    },
  });

  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Your OTP Code for Password Reset',
    text: `Your OTP code is: ${otp}`,
  };

  await transporter.sendMail(mailOptions);
}

// Middleware to clear expired locks on parking slots
async function clearExpiredLocks(req, res, next) {
  try {
    const now = new Date();
    await ParkingSlot.updateMany(
      { lockExpiresAt: { $lte: now } },
      { $set: { lockedBy: null, lockExpiresAt: null } }
    );
    next();
  } catch (err) {
    console.error('Error clearing expired locks:', err);
    next();
  }
}

// Routes

// Request OTP for password reset
app.post('/api/request-otp', async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(404).json({ message: 'User not found.' });

  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  const otpToken = jwt.sign(
    { email, otp },
    process.env.JWT_SECRET,
    { expiresIn: '10m' }
  );

  try {
    await sendOTPEmail(email, otp);
    res.status(200).json({
      message: 'OTP sent to your email.',
      otpToken,
    });
  } catch (error) {
    console.error('Error sending OTP email:', error);
    res.status(500).json({ message: 'Failed to send OTP email.' });
  }
});

// Verify OTP
app.post('/api/verify-otp', (req, res) => {
  const { otpToken, otp } = req.body;

  try {
    const decoded = jwt.verify(otpToken, process.env.JWT_SECRET);
    if (decoded.otp !== otp) return res.status(400).json({ message: 'Invalid OTP.' });

    res.status(200).json({
      message: 'OTP verified successfully.',
      email: decoded.email,
      verifiedToken: jwt.sign({ email: decoded.email }, process.env.JWT_SECRET, { expiresIn: '10m' }),
    });
  } catch (error) {
    res.status(400).json({ message: 'Invalid or expired token.' });
  }
});

// Reset password after OTP verified
app.post('/api/reset-password', async (req, res) => {
  const { otpToken, newPassword } = req.body;

  try {
    const decoded = jwt.verify(otpToken, process.env.JWT_SECRET);
    const email = decoded.email;

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    const updateResult = await User.updateOne({ email }, { password: hashedPassword });

    if (updateResult.modifiedCount === 0) {
      return res.status(400).json({ message: 'Failed to update password.' });
    }

    res.status(200).json({ message: 'Password has been reset successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Failed to reset password.' });
  }
});

// User registration
app.post('/api/users', async (req, res) => {
  const { fullName, email, userName, password } = req.body;

  try {
    if (await User.findOne({ email })) return res.status(400).json({ message: 'Email already in use.' });
    if (await User.findOne({ userName })) return res.status(400).json({ message: 'Username already taken.' });

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = new User({
      fullName,
      email,
      userName,
      password: hashedPassword,
      wallet: { balance: 0, lastUpdated: new Date() },
    });

    await newUser.save();

    res.status(201).json({ message: 'User created successfully.' });
  } catch (error) {
    res.status(500).json({ message: 'Server error.' });
  }
});

// User login
app.post('/api/login', async (req, res) => {
  const { userName, password } = req.body;

  try {
    if (!userName || !password) return res.status(400).json({ message: 'Username and password are required.' });

    const user = await User.findOne({ userName });
    if (!user) return res.status(401).json({ message: 'Invalid credentials.' });

    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch) return res.status(401).json({ message: 'Invalid credentials.' });

    res.status(200).json({
      message: 'Login successful.',
      user: {
        id: user._id,
        fullName: user.fullName,
        email: user.email,
        userName: user.userName,
      },
    });
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get user by username (no password)
app.get('/api/users/username/:userName', async (req, res) => {
  try {
    const user = await User.findOne({ userName: req.params.userName }).select('-password');
    if (!user) return res.status(404).json({ message: 'User not found.' });

    res.status(200).json(user);
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Update user by username
app.put('/api/users/update/username/:userName', async (req, res) => {
  const { fullName, email } = req.body;

  if (!fullName || !email) return res.status(400).json({ message: 'Full Name and Email are required.' });

  try {
    const user = await User.findOne({ userName: req.params.userName });
    if (!user) return res.status(404).json({ message: 'User not found.' });

    user.fullName = fullName;
    user.email = email;
    await user.save();

    res.status(200).json({ message: 'User updated successfully', user });
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Haversine formula for distance calculation
function haversine(lat1, lon1, lat2, lon2) {
  const toRad = (x) => (x * Math.PI) / 180;

  const R = 6371; // km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a = Math.sin(dLat/2) ** 2 + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon/2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Check distance to fixed parking coordinates (just example coords)
app.get('/api/check-distance', (req, res) => {
  const { lat, lon } = req.query;

  if (!lat || !lon) return res.status(400).json({ message: 'Latitude and longitude required.' });

  // Example fixed location (e.g., company parking)
  const parkingLat = 31.963158; 
  const parkingLon = 35.930359;

  const distance = haversine(parseFloat(lat), parseFloat(lon), parkingLat, parkingLon);

  const maxDistanceKm = 1; // max 1 km radius

  res.status(200).json({
    distance,
    isNear: distance <= maxDistanceKm,
  });
});

// Add a charge (owner charges user)
app.post('/api/charges', async (req, res) => {
  const { userId, amount, ownerNumber } = req.body;

  if (!userId || !amount || !ownerNumber) return res.status(400).json({ message: 'Missing parameters.' });

  try {
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: 'User not found.' });

    user.wallet.balance += amount;
    user.wallet.lastUpdated = new Date();
    await user.save();

    const log = new ChargeLog({ userId, amount, ownerNumber, note: `Owner ${ownerNumber} charged user ${user.userName}` });
    await log.save();

    res.status(200).json({ message: 'Charge added successfully.', newBalance: user.wallet.balance });
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// List payments history
app.get('/api/payments', async (req, res) => {
  try {
    const payments = await Payment.find().sort({ date: -1 });
    res.status(200).json(payments);
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Add new payment
app.post('/api/payments', async (req, res) => {
  const { userName, amount, description } = req.body;
  if (!userName || !amount) return res.status(400).json({ message: 'Missing parameters.' });

  try {
    const payment = new Payment({ userName, amount, description });
    await payment.save();
    res.status(201).json({ message: 'Payment added.' });
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Parking slots routes with clearing expired locks middleware

app.use(clearExpiredLocks);

app.get('/api/parking-slots', async (req, res) => {
  try {
    const slots = await ParkingSlot.find();
    res.status(200).json(slots);
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

app.get('/api/parking-slots/available', async (req, res) => {
  try {
    const availableSlots = await ParkingSlot.find({ status: 'available', lockedBy: null });
    res.status(200).json(availableSlots);
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Lock a slot for a user (set lockExpiresAt for 10 minutes)
app.post('/api/parking-slots/lock', async (req, res) => {
  const { slotId, userName } = req.body;

  if (!slotId || !userName) return res.status(400).json({ message: 'Missing parameters.' });

  try {
    const slot = await ParkingSlot.findById(slotId);
    if (!slot) return res.status(404).json({ message: 'Slot not found.' });

    if (slot.lockedBy && slot.lockExpiresAt > new Date()) {
      return res.status(400).json({ message: 'Slot is already locked.' });
    }

    slot.lockedBy = userName;
    slot.lockExpiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 mins from now
    await slot.save();

    res.status(200).json({ message: 'Slot locked successfully.', slot });
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Confirm a parking slot and update wallet deduction
app.post('/api/parking-slots/confirm', async (req, res) => {
  const { slotId, userName, durationHours, ratePerHour } = req.body;

  if (!slotId || !userName || !durationHours || !ratePerHour) {
    return res.status(400).json({ message: 'Missing parameters.' });
  }

  try {
    const slot = await ParkingSlot.findById(slotId);
    if (!slot) return res.status(404).json({ message: 'Slot not found.' });

    if (slot.lockedBy !== userName) {
      return res.status(400).json({ message: 'You have not locked this slot.' });
    }

    const user = await User.findOne({ userName });
    if (!user) return res.status(404).json({ message: 'User not found.' });

    const cost = durationHours * ratePerHour;
    if (user.wallet.balance < cost) {
      return res.status(400).json({ message: 'Insufficient balance.' });
    }

    // Deduct cost
    user.wallet.balance -= cost;
    user.wallet.lastUpdated = new Date();
    await user.save();

    // Update slot
    slot.status = 'occupied';
    slot.userName = userName;
    slot.lockedBy = null;
    slot.lockExpiresAt = null;
    slot.lastUpdated = new Date();
    await slot.save();

    res.status(200).json({ message: 'Parking slot confirmed.', newBalance: user.wallet.balance });
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Stripe payment example endpoint
app.post('/api/stripe-payment', async (req, res) => {
  const { amount, currency = 'usd', paymentMethodId } = req.body;

  if (!amount || !paymentMethodId) {
    return res.status(400).json({ message: 'Missing parameters.' });
  }

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // amount in cents
      currency,
      payment_method: paymentMethodId,
      confirm: true,
    });

    res.status(200).json({ message: 'Payment successful', paymentIntent });
  } catch (error) {
    res.status(400).json({ message: 'Payment failed', error: error.message });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
