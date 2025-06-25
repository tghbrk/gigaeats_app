import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface GroupRequest {
  action: 'get_user_groups' | 'create_group' | 'update_group' | 'add_members' | 'remove_member'
  user_id?: string
  group_id?: string
  name?: string
  description?: string
  type?: string
  member_emails?: string[]
  member_user_id?: string
  settings?: any
}

interface GroupResponse {
  success: boolean
  data?: any
  error?: string
  groups?: any[]
  group?: any
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Verify user authentication
    const {
      data: { user },
      error: authError,
    } = await supabaseClient.auth.getUser()

    if (authError || !user) {
      throw new Error('Unauthorized')
    }

    // Parse request body
    const requestData: GroupRequest = await req.json()
    const { action } = requestData

    console.log(`🔍 [SOCIAL-WALLET-GROUPS] Processing action: ${action} for user: ${user.id} - v2.1`)

    let response: GroupResponse

    switch (action) {
      case 'get_user_groups':
        response = await getUserGroups(supabaseClient, user.id)
        break
      case 'create_group':
        response = await createGroup(supabaseClient, user.id, requestData)
        break
      case 'update_group':
        response = await updateGroup(supabaseClient, user.id, requestData)
        break
      case 'add_members':
        response = await addMembers(supabaseClient, user.id, requestData)
        break
      case 'remove_member':
        response = await removeMember(supabaseClient, user.id, requestData)
        break
      default:
        throw new Error(`Unknown action: ${action}`)
    }

    return new Response(JSON.stringify(response), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    console.error('❌ [SOCIAL-WALLET-GROUPS] Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

// Get user's payment groups
async function getUserGroups(supabaseClient: any, userId: string): Promise<GroupResponse> {
  try {
    console.log(`🔍 [GET-USER-GROUPS] Fetching groups for user: ${userId}`)

    // Get groups where user is creator
    const { data: createdGroups, error: createdError } = await supabaseClient
      .from('payment_groups')
      .select('*')
      .eq('created_by', userId)
      .eq('is_active', true)
      .order('created_at', { ascending: false })

    if (createdError) {
      throw new Error(`Failed to fetch created groups: ${createdError.message}`)
    }

    console.log(`🔍 [GET-USER-GROUPS] Found ${createdGroups.length} created groups`)

    // Get groups where user is a member (simplified approach)
    const { data: memberGroups, error: memberError } = await supabaseClient
      .from('group_members')
      .select(`
        group_id,
        payment_groups (*)
      `)
      .eq('user_id', userId)
      .eq('is_active', true)

    if (memberError) {
      throw new Error(`Failed to fetch member groups: ${memberError.message}`)
    }

    console.log(`🔍 [GET-USER-GROUPS] Found ${memberGroups.length} member groups`)

    // Combine and deduplicate groups
    const allGroupsMap = new Map()

    // Add created groups
    createdGroups.forEach(group => {
      allGroupsMap.set(group.id, group)
    })

    // Add member groups (avoiding duplicates)
    memberGroups.forEach(memberRecord => {
      const group = memberRecord.payment_groups
      if (group && group.is_active && !allGroupsMap.has(group.id)) {
        allGroupsMap.set(group.id, group)
      }
    })

    const groups = Array.from(allGroupsMap.values())

    console.log(`✅ [GET-USER-GROUPS] Found ${groups.length} total groups`)

    return {
      success: true,
      groups: groups
    }
  } catch (error) {
    console.error('❌ [GET-USER-GROUPS] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Create a new payment group
async function createGroup(supabaseClient: any, userId: string, requestData: GroupRequest): Promise<GroupResponse> {
  try {
    const { name, description, type, member_emails, settings } = requestData

    if (!name) {
      throw new Error('Group name is required')
    }

    console.log(`🔍 [CREATE-GROUP] Creating group: ${name} for user: ${userId}`)

    // Create the group
    const { data: group, error: groupError } = await supabaseClient
      .from('payment_groups')
      .insert({
        name,
        description,
        created_by: userId,
        type: type || 'friends',
        settings: settings || {}
      })
      .select()
      .single()

    if (groupError) {
      throw new Error(`Failed to create group: ${groupError.message}`)
    }

    // Add creator as admin member
    const { error: memberError } = await supabaseClient
      .from('group_members')
      .insert({
        group_id: group.id,
        user_id: userId,
        role: 'admin'
      })

    if (memberError) {
      throw new Error(`Failed to add creator as member: ${memberError.message}`)
    }

    // Add other members if provided
    if (member_emails && member_emails.length > 0) {
      await addMembersByEmail(supabaseClient, group.id, member_emails)
    }

    console.log(`✅ [CREATE-GROUP] Group created successfully: ${group.id}`)

    return {
      success: true,
      group
    }
  } catch (error) {
    console.error('❌ [CREATE-GROUP] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Update a payment group
async function updateGroup(supabaseClient: any, userId: string, requestData: GroupRequest): Promise<GroupResponse> {
  try {
    const { group_id, name, description, settings } = requestData

    if (!group_id) {
      throw new Error('Group ID is required')
    }

    console.log(`🔍 [UPDATE-GROUP] Updating group: ${group_id} by user: ${userId}`)

    // Check if user can update this group
    const canAccess = await supabaseClient
      .rpc('user_can_access_group', { user_id: userId, group_id })

    if (!canAccess.data) {
      throw new Error('Access denied: Cannot update this group')
    }

    // Update the group
    const updateData: any = {}
    if (name) updateData.name = name
    if (description !== undefined) updateData.description = description
    if (settings) updateData.settings = settings

    const { data: group, error: updateError } = await supabaseClient
      .from('payment_groups')
      .update(updateData)
      .eq('id', group_id)
      .select()
      .single()

    if (updateError) {
      throw new Error(`Failed to update group: ${updateError.message}`)
    }

    console.log(`✅ [UPDATE-GROUP] Group updated successfully: ${group_id}`)

    return {
      success: true,
      group
    }
  } catch (error) {
    console.error('❌ [UPDATE-GROUP] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Add members to a group
async function addMembers(supabaseClient: any, userId: string, requestData: GroupRequest): Promise<GroupResponse> {
  try {
    const { group_id, member_emails } = requestData

    if (!group_id || !member_emails || member_emails.length === 0) {
      throw new Error('Group ID and member emails are required')
    }

    console.log(`🔍 [ADD-MEMBERS] Adding ${member_emails.length} members to group: ${group_id}`)

    // Check if user can add members to this group
    const canAccess = await supabaseClient
      .rpc('user_can_access_group', { user_id: userId, group_id })

    if (!canAccess.data) {
      throw new Error('Access denied: Cannot add members to this group')
    }

    // Add members by email
    await addMembersByEmail(supabaseClient, group_id, member_emails)

    console.log(`✅ [ADD-MEMBERS] Members added successfully to group: ${group_id}`)

    return {
      success: true,
      data: { message: 'Members added successfully' }
    }
  } catch (error) {
    console.error('❌ [ADD-MEMBERS] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Remove a member from a group
async function removeMember(supabaseClient: any, userId: string, requestData: GroupRequest): Promise<GroupResponse> {
  try {
    const { group_id, member_user_id } = requestData

    if (!group_id || !member_user_id) {
      throw new Error('Group ID and member user ID are required')
    }

    console.log(`🔍 [REMOVE-MEMBER] Removing member ${member_user_id} from group: ${group_id}`)

    // Check if user can remove members from this group
    const canAccess = await supabaseClient
      .rpc('user_can_access_group', { user_id: userId, group_id })

    if (!canAccess.data) {
      throw new Error('Access denied: Cannot remove members from this group')
    }

    // Remove the member
    const { error: removeError } = await supabaseClient
      .from('group_members')
      .delete()
      .eq('group_id', group_id)
      .eq('user_id', member_user_id)

    if (removeError) {
      throw new Error(`Failed to remove member: ${removeError.message}`)
    }

    console.log(`✅ [REMOVE-MEMBER] Member removed successfully from group: ${group_id}`)

    return {
      success: true,
      data: { message: 'Member removed successfully' }
    }
  } catch (error) {
    console.error('❌ [REMOVE-MEMBER] Error:', error)
    return {
      success: false,
      error: error.message
    }
  }
}

// Helper function to add members by email
async function addMembersByEmail(supabaseClient: any, groupId: string, emails: string[]) {
  for (const email of emails) {
    try {
      // Find user by email
      const { data: user } = await supabaseClient
        .from('auth.users')
        .select('id')
        .eq('email', email)
        .single()

      if (user) {
        // Add as member
        await supabaseClient
          .from('group_members')
          .insert({
            group_id: groupId,
            user_id: user.id,
            role: 'member'
          })
      }
    } catch (error) {
      console.warn(`⚠️ [ADD-MEMBER-BY-EMAIL] Could not add ${email}:`, error.message)
    }
  }
}
