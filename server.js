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
app.use(cors());
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
  date: { type: Date, default: Date.now },
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

// Haversine formula for distance calculation
function haversine(lat1, lon1, lat2, lon2) {
  const toRad = (x) => (x * Math.PI) / 180;
  const R = 6371; // km
  const dLat = toRad(lat2 - lat1);
  const dLon = toRad(lon2 - lon1);
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

// Middleware to clear expired locks before any parking slot API
async function clearExpiredLocks(req, res, next) {
  const now = new Date();
  try {
    const result = await ParkingSlot.updateMany(
      { lockExpiresAt: { $lt: now } },
      { $set: { lockedBy: null, lockExpiresAt: null } }
    );
    next();
  } catch (err) {
    console.error('Error clearing expired locks:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
}

// Routes

// Request OTP for password reset
app.post('/api/request-otp', async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(404).json({ message: 'User not found.' });

  const otp = Math.floor(100000 + Math.random() * 900000).toString();

  const otpToken = jwt.sign({ email, otp }, process.env.JWT_SECRET, {
    expiresIn: '10m',
  });

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
    if (decoded.otp !== otp)
      return res.status(400).json({ message: 'Invalid OTP.' });

    res.status(200).json({
      message: 'OTP verified successfully.',
      email: decoded.email,
      verifiedToken: jwt.sign({ email: decoded.email }, process.env.JWT_SECRET, {
        expiresIn: '10m',
      }),
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
    if (await User.findOne({ email }))
      return res.status(400).json({ message: 'Email already in use.' });
    if (await User.findOne({ userName }))
      return res.status(400).json({ message: 'Username already taken.' });

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
    if (!userName || !password)
      return res.status(400).json({ message: 'Username and password are required.' });

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

  if (!fullName || !email)
    return res.status(400).json({ message: 'Full Name and Email are required.' });

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

// Wallet charge route
app.post('/api/wallet/charge', async (req, res) => {
  const { userName, amount, ownerNumber } = req.body;

  if (!userName || !amount || !ownerNumber)
    return res.status(400).json({ message: 'userName, amount, and ownerNumber are required.' });

  try {
    const user = await User.findOne({ userName });
    if (!user) return res.status(404).json({ message: 'User not found.' });

    user.wallet.balance += Number(amount);
    user.wallet.lastUpdated = new Date();

    await user.save();

    // Log the charge
    const chargeLog = new ChargeLog({
      userId: user._id,
      amount: Number(amount),
      ownerNumber,
      note: `Wallet charged by owner ${ownerNumber}`,
    });
    await chargeLog.save();

    res.status(200).json({ message: 'Wallet charged successfully.', wallet: user.wallet });
  } catch {
    res.status(500).json({ message: 'Server error.' });
  }
});

// Stripe payment route
app.post('/api/payment', async (req, res) => {
  const { amount, currency, paymentMethodId, userName, description } = req.body;

  if (!amount || !currency || !paymentMethodId)
    return res.status(400).json({ message: 'amount, currency, and paymentMethodId are required.' });

  try {
    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // cents
      currency,
      payment_method: paymentMethodId,
      confirm: true,
    });

    // Save payment info in DB
    const payment = new Payment({
      userName,
      amount,
      description,
      date: new Date(),
    });

    await payment.save();

    res.status(200).json({ message: 'Payment successful.', paymentIntent });
  } catch (error) {
    console.error('Stripe payment error:', error);
    res.status(500).json({ message: 'Payment failed.' });
  }
});

// Parking slots API

// Use middleware to clear expired locks for /api/slots routes
app.use('/api/slots', clearExpiredLocks);
app.get('/api/slots', async (req, res) => {
  try {
    const slots = await ParkingSlot.find().lean();

    // You can normalize the response here, if needed:
    const normalizedSlots = slots.map(slot => ({
      _id: slot._id,
      slotNumber: slot.slotNumber,
      status: slot.status,
      userName: slot.userName ?? null,       // explicitly null if undefined
      lockedBy: slot.lockedBy ?? null,
      lockExpiresAt: slot.lockExpiresAt ? slot.lockExpiresAt.toISOString() : null,
      lastUpdated: slot.lastUpdated ? slot.lastUpdated.toISOString() : null,
    }));

    res.json(normalizedSlots);
  } catch (error) {
    console.error('Error fetching slots:', error);
    res.status(500).json({ error: 'Failed to fetch slots' });
  }
});

// Lock a slot temporarily
app.post('/api/slots/lock', async (req, res) => {
  const { slotNumber, userName, lockDurationMinutes } = req.body;

  if (!slotNumber || !userName) {
    return res.status(400).json({ error: 'slotNumber and userName are required.' });
  }

  try {
    const now = new Date();
    const lockExpiresAt = new Date(now.getTime() + (lockDurationMinutes || 5) * 60000);

    const slot = await ParkingSlot.findOne({ slotNumber });
    if (!slot) return res.status(404).json({ error: 'Slot not found.' });

    if (slot.lockedBy && slot.lockExpiresAt > now) {
      return res.status(409).json({ error: 'Slot is already locked by another user.' });
    }

    slot.lockedBy = userName;
    slot.lockExpiresAt = lockExpiresAt;
    await slot.save();

    res.json({ message: 'Slot locked successfully.', slot });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Unlock a slot
app.post('/api/slots/unlock', async (req, res) => {
  const { slotNumber, userName } = req.body;

  if (!slotNumber || !userName) {
    return res.status(400).json({ error: 'slotNumber and userName are required.' });
  }

  try {
    const slot = await ParkingSlot.findOne({ slotNumber });
    if (!slot) return res.status(404).json({ error: 'Slot not found.' });

    if (slot.lockedBy !== userName) {
      return res.status(403).json({ error: 'You do not hold the lock on this slot.' });
    }

    slot.lockedBy = null;
    slot.lockExpiresAt = null;
    await slot.save();

    res.json({ message: 'Slot unlocked successfully.', slot });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Update parking slot status (occupied/available)
app.put('/api/slots/:slotNumber/status', async (req, res) => {
  const { slotNumber } = req.params;
  const { status, userName } = req.body;

  if (!['available', 'occupied'].includes(status)) {
    return res.status(400).json({ error: 'Invalid status value.' });
  }

  try {
    const slot = await ParkingSlot.findOne({ slotNumber });
    if (!slot) return res.status(404).json({ error: 'Slot not found.' });

    slot.status = status;
    slot.userName = status === 'occupied' ? userName : null;
    slot.lastUpdated = new Date();

    await slot.save();

    res.json({ message: 'Slot status updated.', slot });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
