import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { initializeApp, cert } from 'https://esm.sh/firebase-admin@11.5.0/app'
import { getAuth } from 'https://esm.sh/firebase-admin@11.5.0/auth'

// Initialize Firebase Admin SDK
const firebaseApp = initializeApp({
  credential: cert({
    projectId: Deno.env.get('FIREBASE_PROJECT_ID'),
    clientEmail: Deno.env.get('FIREBASE_CLIENT_EMAIL'),
    privateKey: Deno.env.get('FIREBASE_PRIVATE_KEY')?.replace(/\\n/g, '\n'),
  }),
})

const auth = getAuth(firebaseApp)

// Function to verify Firebase ID token using Admin SDK
async function verifyFirebaseToken(idToken: string) {
  console.log('Verifying Firebase token with Admin SDK...')

  try {
    // Verify the ID token using Firebase Admin SDK
    const decodedToken = await auth.verifyIdToken(idToken)
    console.log('Firebase token verified successfully:', {
      uid: decodedToken.uid,
      email: decodedToken.email,
      role: decodedToken.role,
      verified: decodedToken.verified
    })

    return decodedToken
  } catch (error) {
    console.error('Firebase token verification failed:', error)
    throw new Error(`Invalid Firebase token: ${error.message}`)
  }
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', {
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    })
  }

  try {
    const { token } = await req.json()

    if (!token) {
      return new Response(
        JSON.stringify({ error: 'Firebase token is required' }),
        { 
          status: 400, 
          headers: { 
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          } 
        }
      )
    }

    // Verify Firebase ID token using Admin SDK
    const decodedToken = await verifyFirebaseToken(token)

    // Create Supabase client with service key
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SERVICE_ROLE_KEY') ?? ''
    )

    // Sync user data to Supabase using decoded token data
    const userData = {
      firebase_uid: decodedToken.uid,
      email: decodedToken.email,
      full_name: decodedToken.name || '',
      phone_number: decodedToken.phone_number || null,
      role: decodedToken.role || 'sales_agent', // Use role from custom claims or default
      is_verified: decodedToken.verified || decodedToken.email_verified || false,
      is_active: decodedToken.active !== false, // Default to true unless explicitly false
      profile_image_url: decodedToken.picture || null,
      updated_at: new Date().toISOString(),
    }

    console.log('Attempting to upsert user data:', userData)

    const { data, error } = await supabase
      .from('users')
      .upsert(userData, { onConflict: 'firebase_uid' })
      .select()
      .single()

    if (error) {
      console.error('Supabase error:', error)
      console.error('Supabase error details:', {
        message: error.message,
        details: error.details,
        hint: error.hint,
        code: error.code
      })
      return new Response(
        JSON.stringify({
          error: 'Failed to sync user data',
          supabase_error: error.message,
          details: error.details,
          hint: error.hint,
          code: error.code
        }),
        {
          status: 500,
          headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
          }
        }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        uid: decodedToken.uid,
        user: data,
        claims: {
          role: decodedToken.role || 'sales_agent',
          verified: decodedToken.verified || false,
          active: decodedToken.active !== false,
          email_verified: decodedToken.email_verified || false,
        }
      }),
      {
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      }
    )
  } catch (error) {
    console.error('Error verifying token:', error)
    console.error('Error details:', {
      message: error.message,
      stack: error.stack,
      name: error.name
    })
    return new Response(
      JSON.stringify({
        error: error.message || 'Failed to verify Firebase token',
        details: error.stack || 'No stack trace available'
      }),
      {
        status: 400,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
        }
      }
    )
  }
})
