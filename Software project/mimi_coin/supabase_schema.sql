-- Mimi Coin Tracker - Supabase Database Schema
-- Run these SQL commands in your Supabase SQL Editor

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
  id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
  email TEXT NOT NULL,
  name TEXT,
  base_currency TEXT DEFAULT 'USD',
  monthly_budget DECIMAL(12, 2),
  financial_goal DECIMAL(12, 2),
  avatar_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- Expenses table
CREATE TABLE IF NOT EXISTS public.expenses (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  category TEXT NOT NULL,
  description TEXT,
  date TIMESTAMP WITH TIME ZONE NOT NULL,
  payment_method TEXT NOT NULL DEFAULT 'Cash',
  group_id UUID,
  is_group_expense BOOLEAN DEFAULT FALSE,
  currency TEXT DEFAULT 'USD',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- Groups table
CREATE TABLE IF NOT EXISTS public.groups (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  created_by UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  currency TEXT DEFAULT 'USD',
  invite_code TEXT UNIQUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW())
);

-- Group members table
CREATE TABLE IF NOT EXISTS public.group_members (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  group_id UUID REFERENCES public.groups(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  role TEXT DEFAULT 'member', -- admin, member
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL,
  UNIQUE(group_id, user_id)
);

-- Expense splits table (for group expenses)
CREATE TABLE IF NOT EXISTS public.expense_splits (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  expense_id UUID REFERENCES public.expenses(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  amount DECIMAL(12, 2) NOT NULL,
  percentage DECIMAL(5, 2),
  is_paid BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Reminders table
CREATE TABLE IF NOT EXISTS public.reminders (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL, -- 'Bill Payment', 'Budget Alert', 'Settlement', 'Custom'
  reminder_date TIMESTAMP WITH TIME ZONE NOT NULL,
  recurrence TEXT DEFAULT 'One-time', -- 'One-time', 'Daily', 'Weekly', 'Monthly', 'Yearly'
  is_active BOOLEAN DEFAULT TRUE,
  related_group_id UUID REFERENCES public.groups(id) ON DELETE SET NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Categories table (for custom categories)
CREATE TABLE IF NOT EXISTS public.categories (
  id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
  user_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
  name TEXT NOT NULL,
  icon_code INT NOT NULL,
  color TEXT,
  is_default BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- Add foreign key for group_id in expenses
ALTER TABLE public.expenses 
ADD CONSTRAINT fk_expense_group 
FOREIGN KEY (group_id) REFERENCES public.groups(id) ON DELETE SET NULL;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_expenses_user_id ON public.expenses(user_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON public.expenses(date);
CREATE INDEX IF NOT EXISTS idx_expenses_category ON public.expenses(category);
CREATE INDEX IF NOT EXISTS idx_expenses_group_id ON public.expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON public.group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON public.group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_user_id ON public.reminders(user_id);
CREATE INDEX IF NOT EXISTS idx_reminders_date ON public.reminders(reminder_date);

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.expense_splits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reminders ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view own profile" ON public.users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.users
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can delete own profile" ON public.users
  FOR DELETE USING (auth.uid() = id);

-- Expenses policies
CREATE POLICY "Users can view own expenses" ON public.expenses
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own expenses" ON public.expenses
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own expenses" ON public.expenses
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own expenses" ON public.expenses
  FOR DELETE USING (auth.uid() = user_id);

-- Security definer function to check group membership without triggering RLS
-- This function runs with elevated privileges and bypasses RLS checks
CREATE OR REPLACE FUNCTION public.is_group_member(check_group_id UUID, check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.group_members 
    WHERE group_id = check_group_id AND user_id = check_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Security definer function to check if user is group creator
CREATE OR REPLACE FUNCTION public.is_group_creator(check_group_id UUID, check_user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.groups 
    WHERE id = check_group_id AND created_by = check_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Groups policies (using security definer function to avoid circular dependency)
CREATE POLICY "Users can view groups they belong to" ON public.groups
  FOR SELECT USING (
    auth.uid() = created_by OR 
    public.is_group_member(id, auth.uid())
  );

CREATE POLICY "Users can create groups" ON public.groups
  FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Group admins can update groups" ON public.groups
  FOR UPDATE USING (auth.uid() = created_by);

CREATE POLICY "Group admins can delete groups" ON public.groups
  FOR DELETE USING (auth.uid() = created_by);

-- Group members policies (using security definer functions to avoid circular dependency)
CREATE POLICY "Users can view members of their groups" ON public.group_members
  FOR SELECT USING (
    -- User can see their own membership
    user_id = auth.uid()
    OR
    -- User can see other members if they are the group creator
    public.is_group_creator(group_id, auth.uid())
    OR
    -- User can see other members if they are also a member
    public.is_group_member(group_id, auth.uid())
  );

CREATE POLICY "Group admins can add members" ON public.group_members
  FOR INSERT WITH CHECK (
    public.is_group_creator(group_id, auth.uid())
    OR user_id = auth.uid() -- Users can add themselves (join via invite)
  );

CREATE POLICY "Group admins can remove members" ON public.group_members
  FOR DELETE USING (
    public.is_group_creator(group_id, auth.uid())
    OR user_id = auth.uid() -- Users can remove themselves
  );

-- Expense splits policies
CREATE POLICY "Users can view splits for their expenses" ON public.expense_splits
  FOR SELECT USING (
    auth.uid() = user_id OR
    EXISTS (SELECT 1 FROM public.expenses WHERE id = expense_id AND user_id = auth.uid())
  );

CREATE POLICY "Users can create splits" ON public.expense_splits
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.expenses WHERE id = expense_id AND user_id = auth.uid())
  );

CREATE POLICY "Users can update their own splits" ON public.expense_splits
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete splits for their expenses" ON public.expense_splits
  FOR DELETE USING (
    EXISTS (SELECT 1 FROM public.expenses WHERE id = expense_id AND user_id = auth.uid())
  );

-- Reminders policies
CREATE POLICY "Users can view own reminders" ON public.reminders
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own reminders" ON public.reminders
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own reminders" ON public.reminders
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own reminders" ON public.reminders
  FOR DELETE USING (auth.uid() = user_id);

-- Categories policies
CREATE POLICY "Users can view own categories" ON public.categories
  FOR SELECT USING (auth.uid() = user_id OR is_default = true);

CREATE POLICY "Users can create own categories" ON public.categories
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own categories" ON public.categories
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own categories" ON public.categories
  FOR DELETE USING (auth.uid() = user_id);

-- Function to automatically create user profile after signup
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, name)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'name', split_part(NEW.email, '@', 1))
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Trigger for new user signup
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = TIMEZONE('utc'::text, NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
CREATE TRIGGER update_users_updated_at
  BEFORE UPDATE ON public.users
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_expenses_updated_at
  BEFORE UPDATE ON public.expenses
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_groups_updated_at
  BEFORE UPDATE ON public.groups
  FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
