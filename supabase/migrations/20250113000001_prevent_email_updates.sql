-- Prevent email updates for security reasons
-- Create a trigger function that prevents email column updates
CREATE OR REPLACE FUNCTION prevent_email_update()
RETURNS TRIGGER AS $$
BEGIN
  -- If email is being changed, raise an error
  IF OLD.email IS DISTINCT FROM NEW.email THEN
    RAISE EXCEPTION 'Email cannot be updated for security reasons. Email changes are not allowed.';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on profiles table to prevent email updates
DROP TRIGGER IF EXISTS prevent_email_update_trigger ON public.profiles;
CREATE TRIGGER prevent_email_update_trigger
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION prevent_email_update();

