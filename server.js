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
  ownerNumber: { type: String, required: true },  // change this to String
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

  await sendOTPEmail(email, otp);

  res.status(200).json({
    message: 'OTP sent to your email.',
    otpToken,
  });
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

// Check distance to fixed parking coordinates
app.post('/check-distance', (req, res) => {
  const { lat, lon } = req.body;

  if (typeof lat !== 'number' || typeof lon !== 'number') {
    return res.status(400).json({ error: 'Invalid or missing lat/lon values' });
  }

  const parkingLat = 31.963158;
  const parkingLon = 35.930359;

  const distance = haversine(lat, lon, parkingLat, parkingLon);
  const maxDistance = 0.1; // km = 100 meters

  res.json({ allowed: distance <= maxDistance });
});

// Charge user wallet and log the charge
app.post('/api/charge-user', async (req, res) => {
  const { userId, amount, ownerNumber } = req.body;

  if (!userId || !amount || !ownerNumber) {
    return res.status(400).json({ message: 'Missing required fields.' });
  }

  try {
    const user = await User.findOne({ _id: userId }); // Assuming userId is MongoDB _id
    if (!user) return res.status(404).json({ message: 'User not found.' });

    user.wallet.balance += amount;
    user.wallet.lastUpdated = new Date();
    await user.save();

    const log = new ChargeLog({
      userId: user._id,
      amount,
      ownerNumber,
      note: `Owner ${ownerNumber} charged user ${userId}`,
    });

    await log.save();

    res.status(200).json({ message: 'Wallet charged and log saved.' });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: 'Server error.' });
  }
});

// Get user wallet balance
app.get('/api/wallet/:userName', async (req, res) => {
  try {
    const user = await User.findOne({ userName: req.params.userName }).select('_id wallet');
    if (!user) return res.status(404).json({ message: 'User not found.' });

    res.status(200).json({
      userID: user._id,
      balance: user.wallet.balance,
      lastUpdated: user.wallet.lastUpdated
    });
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});


// Deduct amount from user's wallet and log the payment
app.post('/api/wallet/deduct', async (req, res) => {
  const { userName, amount, description } = req.body;

  if (!userName || typeof amount !== 'number' || !description) {
    return res.status(400).json({ message: 'Username, amount, and description are required.' });
  }

  try {
    const user = await User.findOne({ userName });

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    if (user.wallet.balance < amount) {
      return res.status(400).json({ message: 'Insufficient wallet balance.' });
    }

    // Deduct balance
    user.wallet.balance -= amount;
    user.wallet.lastUpdated = new Date();
    await user.save();

    // Log payment
    const payment = new Payment({
      userName,
      amount,
      description
    });
    await payment.save();

    res.status(200).json({
      message: 'Amount deducted and payment recorded successfully.',
      newBalance: user.wallet.balance
    });
  } catch (error) {
    console.error('Error deducting amount and logging payment:', error);
    res.status(500).json({ message: 'Server error.' });
  }
});

app.get('/api/payments/:userName', async (req, res) => {
  try {
    const history = await Payment.find({ userName: req.params.userName }).sort({ date: -1 });
    res.status(200).json(history);
  } catch (err) {
    res.status(500).json({ message: 'Server error.' });
  }
});
// Charge wallet from bank (virtual bank integration)
app.post('/api/charge-bank', async (req, res) => {
  const { userName, amount, transactionId } = req.body;

  if (!userName || typeof amount !== 'number') {
    return res.status(400).json({ message: 'Username and amount are required.' });
  }

  try {
    const user = await User.findOne({ userName });

    if (!user) {
      return res.status(404).json({ message: 'User not found.' });
    }

    user.wallet.balance += amount;
    user.wallet.lastUpdated = new Date();
    await user.save();

    // Log the bank top-up in the payments history
    const payment = new Payment({
      userName,
      amount,
      description: transactionId ? `Bank Top-Up (Transaction ID: ${transactionId})` : 'Bank Top-Up'
    });

    await payment.save();

    res.status(200).json({
      message: 'Wallet successfully charged from bank.',
      newBalance: user.wallet.balance
    });

  } catch (error) {
    console.error('Bank top-up error:', error);
    res.status(500).json({ message: 'Server error.' });
  }
});


app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
