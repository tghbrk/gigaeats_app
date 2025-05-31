import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

// Initialize Firebase Admin SDK
admin.initializeApp();

// Valid user roles
const VALID_ROLES = ['sales_agent', 'vendor', 'admin', 'customer'];

/**
 * Cloud Function to set user role as custom claims
 * Called from Flutter app after user registration or role change
 */
export const setUserRole = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to set role.'
    );
  }

  const { uid, role } = data;
  const callerUid = context.auth.uid;

  // Validate input
  if (!uid || !role) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Both uid and role are required.'
    );
  }

  if (!VALID_ROLES.includes(role)) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      `Invalid role. Must be one of: ${VALID_ROLES.join(', ')}`
    );
  }

  try {
    // Check if caller is admin or setting their own role (for initial setup)
    const callerRecord = await admin.auth().getUser(callerUid);
    const callerClaims = callerRecord.customClaims || {};
    const isAdmin = callerClaims.role === 'admin';
    const isSelfAssignment = callerUid === uid;

    // Only admins can set other users' roles, or users can set their own role during initial setup
    if (!isAdmin && !isSelfAssignment) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can set other users\' roles.'
      );
    }

    // If it's self-assignment, only allow if user doesn't have a role yet
    if (isSelfAssignment && callerClaims.role) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Cannot change your own role once it\'s set. Contact an admin.'
      );
    }

    // Set custom claims
    await admin.auth().setCustomUserClaims(uid, {
      role: role,
      verified: false, // Default to unverified
      active: true,
      updated_at: new Date().toISOString()
    });

    functions.logger.info(`Role ${role} set for user ${uid} by ${callerUid}`);

    return {
      success: true,
      message: `Role ${role} successfully set for user ${uid}`,
      role: role
    };

  } catch (error) {
    functions.logger.error('Error setting user role:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to set user role. Please try again.'
    );
  }
});

/**
 * Cloud Function to update user verification status (admin only)
 */
export const setUserVerification = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated.'
    );
  }

  const { uid, verified } = data;
  const callerUid = context.auth.uid;

  // Validate input
  if (!uid || typeof verified !== 'boolean') {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'Both uid and verified status are required.'
    );
  }

  try {
    // Check if caller is admin
    const callerRecord = await admin.auth().getUser(callerUid);
    const callerClaims = callerRecord.customClaims || {};
    
    if (callerClaims.role !== 'admin') {
      throw new functions.https.HttpsError(
        'permission-denied',
        'Only admins can update user verification status.'
      );
    }

    // Get current user claims
    const userRecord = await admin.auth().getUser(uid);
    const currentClaims = userRecord.customClaims || {};

    // Update verification status
    await admin.auth().setCustomUserClaims(uid, {
      ...currentClaims,
      verified: verified,
      updated_at: new Date().toISOString()
    });

    functions.logger.info(`Verification status ${verified} set for user ${uid} by admin ${callerUid}`);

    return {
      success: true,
      message: `User ${uid} verification status updated to ${verified}`,
      verified: verified
    };

  } catch (error) {
    functions.logger.error('Error setting user verification:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to update verification status. Please try again.'
    );
  }
});

/**
 * Cloud Function to get user claims (for debugging/admin purposes)
 */
export const getUserClaims = functions.https.onCall(async (data, context) => {
  // Check if user is authenticated
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated.'
    );
  }

  const { uid } = data;
  const callerUid = context.auth.uid;

  try {
    // Users can get their own claims, admins can get any user's claims
    const callerRecord = await admin.auth().getUser(callerUid);
    const callerClaims = callerRecord.customClaims || {};
    const isAdmin = callerClaims.role === 'admin';
    const isSelf = callerUid === (uid || callerUid);

    if (!isAdmin && !isSelf) {
      throw new functions.https.HttpsError(
        'permission-denied',
        'You can only view your own claims unless you are an admin.'
      );
    }

    const targetUid = uid || callerUid;
    const userRecord = await admin.auth().getUser(targetUid);
    
    return {
      success: true,
      uid: targetUid,
      claims: userRecord.customClaims || {},
      email: userRecord.email,
      emailVerified: userRecord.emailVerified
    };

  } catch (error) {
    functions.logger.error('Error getting user claims:', error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    
    throw new functions.https.HttpsError(
      'internal',
      'Failed to get user claims. Please try again.'
    );
  }
});

/**
 * Trigger function that runs when a user is created
 * Sets default role and syncs to Supabase
 */
export const onUserCreate = functions.auth.user().onCreate(async (user) => {
  try {
    // Set default custom claims for new users
    await admin.auth().setCustomUserClaims(user.uid, {
      role: 'sales_agent', // Default role
      verified: false,
      active: true,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString()
    });

    functions.logger.info(`Default claims set for new user: ${user.uid}`);

    // TODO: Trigger Supabase sync here if needed
    // This could call the Supabase Edge Function to sync user data

  } catch (error) {
    functions.logger.error('Error setting default claims for new user:', error);
  }
});
