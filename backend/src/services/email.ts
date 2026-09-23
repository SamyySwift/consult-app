import { Resend } from 'resend';
import dotenv from 'dotenv';

dotenv.config();

const resendApiKey = process.env.RESEND_API_KEY;
const resend = resendApiKey ? new Resend(resendApiKey) : null;
const fromEmail = process.env.SENDER_EMAIL || 'onboarding@resend.dev';

export async function sendOtpEmail(toEmail: string, otpCode: string): Promise<boolean> {
  console.log(`📨 [OTP Dispatch] Target: ${toEmail} | Code: ${otpCode}`);

  if (!resend) {
    console.warn('⚠️ RESEND_API_KEY not configured. OTP printed above for testing.');
    return true;
  }

  try {
    const { data, error } = await resend.emails.send({
      from: `Carpital Consult <${fromEmail}>`,
      to: [toEmail],
      subject: `${otpCode} is your Carpital Consult verification code`,
      html: `
        <!DOCTYPE html>
        <html>
        <head>
          <meta charset="utf-8">
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #0c0d0e; color: #ffffff; padding: 40px 20px; margin: 0; }
            .container { max-width: 500px; margin: 0 auto; background-color: #17181c; border-radius: 20px; padding: 36px; border: 1px solid #282a30; box-shadow: 0 8px 30px rgba(0,0,0,0.4); text-align: center; }
            .logo { font-size: 24px; font-weight: 800; color: #10B981; letter-spacing: -0.5px; margin-bottom: 24px; }
            h1 { font-size: 22px; font-weight: 700; margin-bottom: 12px; color: #ffffff; }
            p { font-size: 14px; color: #9ca3af; line-height: 1.6; margin: 0 0 20px; }
            .otp-box { background: #22252c; border: 1.5px solid #10B981; border-radius: 12px; font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #10B981; padding: 18px 24px; display: inline-block; margin: 16px 0 24px; }
            .footer { font-size: 12px; color: #6b7280; border-top: 1px solid #282a30; padding-top: 20px; margin-top: 28px; }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="logo">⚡ Carpital Consult</div>
            <h1>Verify Your Email</h1>
            <p>Welcome! Please enter this 6-digit code in the app to complete your account registration:</p>
            <div class="otp-box">${otpCode}</div>
            <p>This verification code is valid for <strong>10 minutes</strong>. If you did not request this, you can safely ignore this email.</p>
            <div class="footer">
              &copy; ${new Date().getFullYear()} Carpital Consult Logistics. All rights reserved.
            </div>
          </div>
        </body>
        </html>
      `,
    });

    if (error) {
      console.error('❌ Resend API Error:', error);
      return false;
    }

    console.log('✅ Email sent successfully via Resend:', data?.id);
    return true;
  } catch (err) {
    console.error('❌ Failed to send email via Resend:', err);
    return false;
  }
}
