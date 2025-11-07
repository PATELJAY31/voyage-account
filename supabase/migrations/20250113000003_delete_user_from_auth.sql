-- Function to delete user from auth.users table
-- This function can be called by admins to completely delete a user account
CREATE OR REPLACE FUNCTION delete_user_from_auth(user_id_to_delete UUID)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- Only allow admins to delete users
  IF NOT public.has_role(auth.uid(), 'admin') THEN
    RAISE EXCEPTION 'Only admins can delete users';
  END IF;

  -- Delete from auth.users
  DELETE FROM auth.users
  WHERE id = user_id_to_delete;
END;
$$;

-- Grant execute permission to authenticated users (RLS will check admin role)
GRANT EXECUTE ON FUNCTION delete_user_from_auth(UUID) TO authenticated;

