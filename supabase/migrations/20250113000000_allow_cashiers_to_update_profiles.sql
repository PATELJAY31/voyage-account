-- Allow cashiers to update other users' profiles (for balance management)
-- Cashiers cannot update their own profile (enforced in application code)
CREATE POLICY "Cashiers can update other profiles"
  ON public.profiles FOR UPDATE
  USING (
    public.has_role(auth.uid(), 'cashier') AND
    auth.uid() != user_id
  )
  WITH CHECK (
    public.has_role(auth.uid(), 'cashier') AND
    auth.uid() != user_id
  );

