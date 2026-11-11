const functions = require('firebase-functions');
const admin = require('firebase-admin');
const crypto = require('crypto');
const { Resend } = require('resend');

admin.initializeApp();
const db = admin.firestore();

/**
 * Helper to compute SHA-256 hash of OTP code
 */
function hashOtp(code) {
  return crypto.createHash('sha256').update(code.toString()).digest('hex');
}

/**
 * 1. requestLoginOtp
 * Generates a single-use 6-digit OTP bound to a new server sessionId.
 * Atomically enforces cooldown & hourly limits using persistent otp_rate_limits records.
 * Secret Manager bindings: RESEND_API_KEY, FROM_EMAIL
 */
exports.requestLoginOtp = functions
  .runWith({ secrets: ['RESEND_API_KEY', 'FROM_EMAIL'] })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated via email/password.');
    }

    if (!context.auth.token.email_verified) {
      throw new functions.https.HttpsError('failed-precondition', 'Email address must be verified before requesting a login code.');
    }

    const uid = context.auth.uid;
    const userEmail = context.auth.token.email;

    if (!userEmail) {
      throw new functions.https.HttpsError('failed-precondition', 'User account does not have an associated email address.');
    }

    const nowMillis = Date.now();
    const COOLDOWN_SECONDS = 60;
    const ONE_HOUR_MILLIS = 60 * 60 * 1000;
    const MAX_HOURLY_REQUESTS = 5;

    // Persistent Rate Limiting Check in transaction
    const rateLimitRef = db.collection('otp_rate_limits').doc(uid);
    const rateLimitOutcome = await db.runTransaction(async (transaction) => {
      const doc = await transaction.get(rateLimitRef);
      let lastRequestedAt = 0;
      let hourlyWindowStart = nowMillis;
      let hourlyCount = 0;

      if (doc.exists) {
        const d = doc.data();
        lastRequestedAt = d.lastRequestedAt ? d.lastRequestedAt.toMillis() : 0;
        hourlyWindowStart = d.hourlyWindowStart ? d.hourlyWindowStart.toMillis() : nowMillis;
        hourlyCount = d.hourlyCount || 0;
      }

      // Check 60-second cooldown
      const elapsedSeconds = Math.floor((nowMillis - lastRequestedAt) / 1000);
      if (elapsedSeconds < COOLDOWN_SECONDS) {
        return { outcome: 'COOLDOWN', waitSeconds: COOLDOWN_SECONDS - elapsedSeconds };
      }

      // Check hourly limit window
      if (nowMillis - hourlyWindowStart > ONE_HOUR_MILLIS) {
        hourlyWindowStart = nowMillis;
        hourlyCount = 1;
      } else {
        if (hourlyCount >= MAX_HOURLY_REQUESTS) {
          const resetInMinutes = Math.ceil((ONE_HOUR_MILLIS - (nowMillis - hourlyWindowStart)) / (60 * 1000));
          return { outcome: 'HOURLY_LIMIT', resetInMinutes };
        }
        hourlyCount += 1;
      }

      transaction.set(rateLimitRef, {
        uid: uid,
        lastRequestedAt: admin.firestore.Timestamp.fromMillis(nowMillis),
        hourlyWindowStart: admin.firestore.Timestamp.fromMillis(hourlyWindowStart),
        hourlyCount: hourlyCount,
      }, { merge: true });

      return { outcome: 'ALLOWED' };
    });

    if (rateLimitOutcome.outcome === 'COOLDOWN') {
      throw new functions.https.HttpsError('resource-exhausted', `Please wait ${rateLimitOutcome.waitSeconds} seconds before requesting a new code.`);
    }

    if (rateLimitOutcome.outcome === 'HOURLY_LIMIT') {
      throw new functions.https.HttpsError('resource-exhausted', `Hourly code request limit reached. Please try again in ${rateLimitOutcome.resetInMinutes} minute(s).`);
    }

    // Generate cryptographically secure 6-digit OTP and unique sessionId
    const sessionId = crypto.randomUUID();
    const rawOtp = crypto.randomInt(100000, 1000000).toString();
    const codeHash = hashOtp(rawOtp);

    const expiresAtMillis = nowMillis + 5 * 60 * 1000; // 5-minute TTL

    // Store OTP challenge document keyed by sessionId
    await db.collection('otp_challenges').doc(sessionId).set({
      uid: uid,
      sessionId: sessionId,
      codeHash: codeHash,
      attemptsCount: 0,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromMillis(expiresAtMillis),
    });

    // Verify secrets are configured
    const resendApiKey = process.env.RESEND_API_KEY;
    const FROM_EMAIL = process.env.FROM_EMAIL;

    if (!resendApiKey) {
      console.error('[AUTH ERROR] RESEND_API_KEY secret is not configured.');
      throw new functions.https.HttpsError('failed-precondition', 'Email verification service is not configured. Please contact support.');
    }

    if (!FROM_EMAIL) {
      console.error('[AUTH ERROR] FROM_EMAIL secret is not configured.');
      throw new functions.https.HttpsError('failed-precondition', 'Email sender domain is not configured. Please contact support.');
    }

    const resend = new Resend(resendApiKey);

    try {
      const response = await resend.emails.send({
        from: FROM_EMAIL,
        to: [userEmail],
        subject: 'Your FinanceTracker Verification Code',
        html: `
          <div style="font-family: sans-serif; padding: 20px; color: #333;">
            <h2>FinanceTracker Verification Code</h2>
            <p>Your one-time login verification code is:</p>
            <h1 style="font-size: 36px; letter-spacing: 4px; color: #1a73e8;">${rawOtp}</h1>
            <p>This code will expire in <strong>5 minutes</strong>.</p>
            <p>If you did not attempt to log in, please secure your account immediately.</p>
          </div>
        `,
      });

      if (response && response.error) {
        console.error('Resend API returned error:', response.error);
        throw new functions.https.HttpsError('internal', 'Failed to send verification email. Please try again later.');
      }
    } catch (emailErr) {
      if (emailErr instanceof functions.https.HttpsError) {
        throw emailErr;
      }
      console.error('Failed to send email via Resend:', emailErr.message || emailErr);
      throw new functions.https.HttpsError('internal', 'Failed to send verification email. Please try again later.');
    }

    return {
      sessionId: sessionId,
      expiresAt: expiresAtMillis,
      cooldownSeconds: 60,
    };
  });

/**
 * 2. verifyLoginOtp
 * Verifies submitted OTP atomically. Commits attempt counters and verified session before returning custom token.
 */
exports.verifyLoginOtp = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated.');
  }

  if (!context.auth.token.email_verified) {
    throw new functions.https.HttpsError('failed-precondition', 'Email address must be verified before completing login.');
  }

  const { sessionId, code } = data || {};

  // Input Type and Format Validation
  if (typeof sessionId !== 'string' || sessionId.trim().length === 0 || sessionId.trim().length > 100) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid or missing sessionId format.');
  }

  if (typeof code !== 'string' || !/^\d{6}$/.test(code.trim())) {
    throw new functions.https.HttpsError('invalid-argument', 'Verification code must be exactly 6 digits.');
  }

  const uid = context.auth.uid;
  const cleanSessionId = sessionId.trim();
  const challengeRef = db.collection('otp_challenges').doc(cleanSessionId);

  // Atomic transaction to verify OTP, track attempts, commit writes before throwing
  const txResult = await db.runTransaction(async (transaction) => {
    const doc = await transaction.get(challengeRef);
    if (!doc.exists) {
      return { outcome: 'NOT_FOUND' };
    }

    const challengeData = doc.data();

    if (challengeData.uid !== uid) {
      return { outcome: 'OWNERSHIP_MISMATCH' };
    }

    if (challengeData.expiresAt.toMillis() <= Date.now()) {
      transaction.delete(challengeRef);
      return { outcome: 'EXPIRED' };
    }

    if (challengeData.attemptsCount >= 3) {
      transaction.delete(challengeRef);
      return { outcome: 'MAX_ATTEMPTS_EXCEEDED' };
    }

    const submittedHash = hashOtp(code.trim());
    if (submittedHash !== challengeData.codeHash) {
      const newAttempts = (challengeData.attemptsCount || 0) + 1;
      if (newAttempts >= 3) {
        transaction.delete(challengeRef);
        return { outcome: 'MAX_ATTEMPTS_EXCEEDED' };
      } else {
        transaction.update(challengeRef, { attemptsCount: newAttempts });
        return { outcome: 'WRONG_CODE', remainingAttempts: 3 - newAttempts };
      }
    }

    // Code matched! Delete challenge doc (single-use) and write verified session doc
    transaction.delete(challengeRef);
    const verifiedSessionRef = db.collection('verified_sessions').doc(cleanSessionId);
    transaction.set(verifiedSessionRef, {
      uid: uid,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      expiresAt: admin.firestore.Timestamp.fromMillis(Date.now() + 24 * 60 * 60 * 1000), // 24 hours
      revoked: false,
    });

    return { outcome: 'SUCCESS' };
  });

  // Handle outcome outside transaction so transaction writes ARE committed
  switch (txResult.outcome) {
    case 'NOT_FOUND':
      throw new functions.https.HttpsError('not-found', 'Verification session expired or invalid. Please request a new code.');
    case 'OWNERSHIP_MISMATCH':
      throw new functions.https.HttpsError('permission-denied', 'Session ownership mismatch.');
    case 'EXPIRED':
      throw new functions.https.HttpsError('deadline-exceeded', 'Verification code has expired. Please request a new code.');
    case 'MAX_ATTEMPTS_EXCEEDED':
      throw new functions.https.HttpsError('resource-exhausted', 'Maximum verification attempts exceeded. Code invalidated.');
    case 'WRONG_CODE':
      throw new functions.https.HttpsError('invalid-argument', `Incorrect code. ${txResult.remainingAttempts} attempt(s) remaining.`);
    case 'SUCCESS':
      break;
    default:
      throw new functions.https.HttpsError('internal', 'An unexpected verification error occurred.');
  }

  // Issue Custom Token ONLY after successful verification commit
  try {
    const customToken = await admin.auth().createCustomToken(uid, {
      session_id: cleanSessionId,
    });
    return { customToken: customToken };
  } catch (err) {
    console.error('Error generating custom token:', err);
    throw new functions.https.HttpsError('internal', 'Failed to generate session token.');
  }
});

/**
 * 3. logoutSession
 * Uses authenticated token's session_id, verifies ownership, and reports revocation failures.
 */
exports.logoutSession = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated to log out.');
  }

  const sessionId = context.auth.token ? context.auth.token.session_id : null;
  if (!sessionId || typeof sessionId !== 'string' || sessionId.trim().length === 0) {
    throw new functions.https.HttpsError('failed-precondition', 'No active verified session claim found in authentication token.');
  }

  const sessionRef = db.collection('verified_sessions').doc(sessionId);

  try {
    const sessionDoc = await sessionRef.get();
    if (!sessionDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Session record not found.');
    }

    const sessionData = sessionDoc.data();
    if (sessionData.uid !== context.auth.uid) {
      throw new functions.https.HttpsError('permission-denied', 'Session ownership mismatch.');
    }

    await sessionRef.update({
      revoked: true,
      revokedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true };
  } catch (err) {
    if (err instanceof functions.https.HttpsError) {
      throw err;
    }
    console.error('Error revoking session:', err);
    throw new functions.https.HttpsError('internal', 'Failed to revoke session. Please try again.');
  }
});
