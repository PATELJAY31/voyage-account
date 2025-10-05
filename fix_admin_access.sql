-- Fix RLS policies for admin access
-- Run this in your Supabase SQL Editor

-- Add policy for users to insert their own roles
CREATE POLICY "Users can insert their own roles"
  ON public.user_roles FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Add policy for users to update their own roles  
CREATE POLICY "Users can update their own roles"
  ON public.user_roles FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Test the has_role function
SELECT public.has_role(auth.uid(), 'admin') as is_admin;

-- Check current user roles
SELECT * FROM public.user_roles WHERE user_id = auth.uid();

-- Test expenses query with admin access
SELECT 
  e.*,
  p.name as user_name,
  p.email as user_email
FROM public.expenses e
JOIN public.profiles p ON e.user_id = p.user_id
ORDER BY e.created_at DESC;
