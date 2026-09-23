import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { pool } from '../db';
import { sendOtpEmail } from '../services/email';

export const authRouter = Router();

const JWT_SECRET = process.env.JWT_SECRET || 'carpital_consult_super_secret_jwt_key_2026';

function generate6DigitOtp(): string {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// -------------------------------------------------------------
// POST /register
// -------------------------------------------------------------
authRouter.post('/register', async (req: Request, res: Response): Promise<void> => {
  const { firstName, lastName, email, phone, password } = req.body;

  if (!email || !password || !firstName) {
    res.status(400).json({ error: 'First name, email, and password are required' });
    return;
  }

  const cleanEmail = email.trim().toLowerCase();
  const cleanFirst = firstName.trim();
  const cleanLast = (lastName || '').trim();
  const cleanPhone = (phone || '').trim();

  try {
    // Check if verified user exists
    const existing = await pool.query('SELECT id, is_verified FROM public.users WHERE email = $1', [cleanEmail]);
    if (existing.rows.length > 0 && existing.rows[0].is_verified) {
      res.status(409).json({ error: 'An account with this email already exists' });
      return;
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    let userId: string;

    if (existing.rows.length > 0) {
      // User exists but unverified: update password and names
      const updated = await pool.query(
        `UPDATE public.users 
         SET first_name = $1, last_name = $2, phone = $3, password_hash = $4, updated_at = NOW() 
         WHERE email = $5 RETURNING id`,
        [cleanFirst, cleanLast, cleanPhone, passwordHash, cleanEmail]
      );
      userId = updated.rows[0].id;
    } else {
      // Create new user
      const inserted = await pool.query(
        `INSERT INTO public.users (first_name, last_name, email, phone, password_hash)
         VALUES ($1, $2, $3, $4, $5) RETURNING id`,
        [cleanFirst, cleanLast, cleanEmail, cleanPhone, passwordHash]
      );
      userId = inserted.rows[0].id;
    }

    // Generate 6-digit OTP
    const otp = generate6DigitOtp();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Invalidate old unverified OTPs for this email
    await pool.query(
      `DELETE FROM public.email_verifications WHERE email = $1`,
      [cleanEmail]
    );

    // Save new OTP
    await pool.query(
      `INSERT INTO public.email_verifications (email, otp_code, expires_at)
       VALUES ($1, $2, $3)`,
      [cleanEmail, otp, expiresAt]
    );

    // Dispatch OTP via Resend
    await sendOtpEmail(cleanEmail, otp);

    res.status(201).json({
      success: true,
      message: 'Verification code sent to your email',
      email: cleanEmail,
      userId,
    });
  } catch (err: any) {
    console.error('Registration error:', err);
    res.status(500).json({ error: 'Server error during registration. Please try again.' });
  }
});

// -------------------------------------------------------------
// POST /verify-otp
// -------------------------------------------------------------
authRouter.post('/verify-otp', async (req: Request, res: Response): Promise<void> => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    res.status(400).json({ error: 'Email and OTP code are required' });
    return;
  }

  const cleanEmail = email.trim().toLowerCase();
  const cleanOtp = otp.toString().trim();

  try {
    const result = await pool.query(
      `SELECT id, expires_at, verified 
       FROM public.email_verifications 
       WHERE email = $1 AND otp_code = $2 
       ORDER BY created_at DESC LIMIT 1`,
      [cleanEmail, cleanOtp]
    );

    if (result.rows.length === 0) {
      res.status(400).json({ error: 'Invalid verification code' });
      return;
    }

    const verification = result.rows[0];

    if (new Date(verification.expires_at) < new Date()) {
      res.status(400).json({ error: 'Verification code has expired. Please request a new one.' });
      return;
    }

    // Mark verification as used
    await pool.query(
      `UPDATE public.email_verifications SET verified = TRUE WHERE id = $1`,
      [verification.id]
    );

    // Mark user as verified
    const userUpdate = await pool.query(
      `UPDATE public.users 
       SET is_verified = TRUE, updated_at = NOW() 
       WHERE email = $1 
       RETURNING id, first_name, last_name, email, phone, avatar_url, role, created_at`,
      [cleanEmail]
    );

    if (userUpdate.rows.length === 0) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    const user = userUpdate.rows[0];

    // Issue JWT Token
    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      message: 'Email verified successfully',
      token,
      user: {
        id: user.id,
        firstName: user.first_name,
        lastName: user.last_name,
        email: user.email,
        phone: user.phone,
        avatarUrl: user.avatar_url,
        createdAt: user.created_at,
      },
    });
  } catch (err: any) {
    console.error('OTP verification error:', err);
    res.status(500).json({ error: 'Server error verifying OTP' });
  }
});

// -------------------------------------------------------------
// POST /resend-otp
// -------------------------------------------------------------
authRouter.post('/resend-otp', async (req: Request, res: Response): Promise<void> => {
  const { email } = req.body;

  if (!email) {
    res.status(400).json({ error: 'Email is required' });
    return;
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    const user = await pool.query('SELECT id, is_verified FROM public.users WHERE email = $1', [cleanEmail]);
    if (user.rows.length === 0) {
      res.status(404).json({ error: 'No account found with this email' });
      return;
    }

    if (user.rows[0].is_verified) {
      res.status(400).json({ error: 'This account is already verified. Please sign in.' });
      return;
    }

    const otp = generate6DigitOtp();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

    await pool.query(
      `DELETE FROM public.email_verifications WHERE email = $1`,
      [cleanEmail]
    );

    await pool.query(
      `INSERT INTO public.email_verifications (email, otp_code, expires_at)
       VALUES ($1, $2, $3)`,
      [cleanEmail, otp, expiresAt]
    );

    await sendOtpEmail(cleanEmail, otp);

    res.json({
      success: true,
      message: 'New verification code sent to your email',
    });
  } catch (err: any) {
    console.error('Resend OTP error:', err);
    res.status(500).json({ error: 'Failed to resend code' });
  }
});

// -------------------------------------------------------------
// POST /login
// -------------------------------------------------------------
authRouter.post('/login', async (req: Request, res: Response): Promise<void> => {
  const { email, password } = req.body;

  if (!email || !password) {
    res.status(400).json({ error: 'Email and password are required' });
    return;
  }

  const cleanEmail = email.trim().toLowerCase();

  try {
    const result = await pool.query(
      `SELECT id, first_name, last_name, email, phone, password_hash, avatar_url, role, is_verified, created_at 
       FROM public.users WHERE email = $1`,
      [cleanEmail]
    );

    if (result.rows.length === 0) {
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

    const user = result.rows[0];

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      res.status(401).json({ error: 'Invalid email or password' });
      return;
    }

    if (!user.is_verified) {
      // Re-send OTP if unverified
      const otp = generate6DigitOtp();
      const expiresAt = new Date(Date.now() + 10 * 60 * 1000);

      await pool.query(`DELETE FROM public.email_verifications WHERE email = $1`, [cleanEmail]);
      await pool.query(
        `INSERT INTO public.email_verifications (email, otp_code, expires_at) VALUES ($1, $2, $3)`,
        [cleanEmail, otp, expiresAt]
      );
      await sendOtpEmail(cleanEmail, otp);

      res.status(403).json({
        error: 'Email not verified. A new verification code has been sent.',
        code: 'EMAIL_NOT_VERIFIED',
        email: cleanEmail,
      });
      return;
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, role: user.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    res.json({
      success: true,
      token,
      user: {
        id: user.id,
        firstName: user.first_name,
        lastName: user.last_name,
        email: user.email,
        phone: user.phone,
        avatarUrl: user.avatar_url,
        createdAt: user.created_at,
      },
    });
  } catch (err: any) {
    console.error('Login error:', err);
    res.status(500).json({ error: 'Server error during login' });
  }
});

// -------------------------------------------------------------
// GET /me (Current User Profile)
// -------------------------------------------------------------
authRouter.get('/me', async (req: Request, res: Response): Promise<void> => {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Unauthorized. Token required.' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = jwt.verify(token, JWT_SECRET) as { id: string };
    const result = await pool.query(
      `SELECT id, first_name, last_name, email, phone, avatar_url, role, created_at 
       FROM public.users WHERE id = $1`,
      [decoded.id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'User not found' });
      return;
    }

    const user = result.rows[0];
    res.json({
      id: user.id,
      firstName: user.first_name,
      lastName: user.last_name,
      email: user.email,
      phone: user.phone,
      avatarUrl: user.avatar_url,
      createdAt: user.created_at,
    });
  } catch (err) {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
});
