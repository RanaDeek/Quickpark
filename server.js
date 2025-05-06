const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const nodemailer = require('nodemailer');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// MongoDB Connection String (MongoDB Atlas)
const mongoURI = process.env.MONGO_URI;

mongoose.connect(mongoURI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('✅ Connected to MongoDB Atlas'))
.catch(err => console.error('❌ MongoDB Error:', err));

// User Schema and Model
const userSchema = new mongoose.Schema({
  fullName: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  userName: { type: String, required: true, unique: true },
  password: { type: String, required: true },
});

const User = mongoose.model('User', userSchema);

// Send OTP Email
const sendOTPEmail = async (email, otp) => {
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
};

// Request OTP
app.post('/api/request-otp', async (req, res) => {
  const { email } = req.body;
  const user = await User.findOne({ email });
  if (!user) return res.status(404).json({ message: 'User not found.' });

  const otp = Math.floor(100000 + Math.random() * 900000).toString(); // 6-digit OTP

  // Sign OTP into a JWT (expires in 10 minutes)
  const otpToken = jwt.sign(
    { email, otp },
    process.env.JWT_SECRET,  // Use the JWT secret
    { expiresIn: '10m' }
  );

  await sendOTPEmail(email, otp); // Send OTP via email

  return res.status(200).json({
    message: 'OTP sent to your email.',
    otpToken, // Send token to client
  });
});
app.post('/api/verify-otp', async (req, res) => {
    const { otpToken, otp, newPassword } = req.body;
  
    try {
      // Verify the OTP token using JWT
      const decoded = jwt.verify(otpToken, process.env.JWT_SECRET);
  
      if (decoded.otp !== otp) {
        return res.status(400).json({ message: 'Invalid OTP.' });
      }
  
      const user = await User.findOne({ email: decoded.email });
      if (!user) return res.status(404).json({ message: 'User not found.' });
  
      // Hash the new password and update the user
      user.password = await bcrypt.hash(newPassword, 10);
      await user.save();
  
      return res.status(200).json({ message: 'Password has been reset successfully.' });
    } catch (error) {
      console.error(error);
      return res.status(400).json({ message: 'Invalid or expired token.' });
    }
  });
  
// POST endpoint to create a new user (User registration)
app.post('/api/users', async (req, res) => {
    const { fullName, email, userName, password } = req.body;
  
    try {
      // Check if the user already exists
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ message: 'Email already in use.' });
      }
  
      const existingUserName = await User.findOne({ userName });
      if (existingUserName) {
        return res.status(400).json({ message: 'Username already taken.' });
      }
  
      // Hash the password
      const hashedPassword = await bcrypt.hash(password, 10);
  
      // Create a new user
      const newUser = new User({
        fullName,
        email,
        userName,
        password: hashedPassword,
      });
  
      // Save the user to the database
      await newUser.save();
  
      return res.status(201).json({ message: 'User created successfully.' });
    } catch (error) {
      console.error(error);
      return res.status(500).json({ message: 'Server error.' });
    }
  });
  // 3. Reset Password
router.post('/reset-password', async (req, res) => {
    const { otpToken, newPassword } = req.body;
  
    try {
      const decoded = jwt.verify(otpToken, process.env.JWT_SECRET);
      const { email } = decoded;
  
      const hashedPassword = await bcrypt.hash(newPassword, 10);
      await User.findOneAndUpdate({ email }, { password: hashedPassword });
  
      res.json({ message: 'Password updated successfully' });
    } catch (err) {
      res.status(401).json({ message: 'Token expired or invalid' });
    }
  });
  
  
// Start Server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
});
