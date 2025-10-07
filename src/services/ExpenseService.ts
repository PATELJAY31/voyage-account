import { supabase } from "@/integrations/supabase/client";
import { Database } from "@/integrations/supabase/types";

type Expense = Database["public"]["Tables"]["expenses"]["Row"];
type ExpenseInsert = Database["public"]["Tables"]["expenses"]["Insert"];
type ExpenseUpdate = Database["public"]["Tables"]["expenses"]["Update"];
type LineItem = Database["public"]["Tables"]["expense_line_items"]["Row"];
type LineItemInsert = Database["public"]["Tables"]["expense_line_items"]["Insert"];

export interface ExpenseWithLineItems extends Expense {
  expense_line_items: LineItem[];
}

export interface CreateExpenseData {
  title: string;
  destination: string;
  trip_start: string;
  trip_end: string;
  purpose?: string;
  line_items: Array<{
    date: string;
    category: "travel" | "lodging" | "food" | "other";
    amount: number;
    description: string;
  }>;
}

export interface UpdateExpenseData {
  title?: string;
  destination?: string;
  trip_start?: string;
  trip_end?: string;
  purpose?: string;
  status?: "draft" | "submitted" | "under_review" | "verified" | "approved" | "rejected" | "paid";
  admin_comment?: string;
  assigned_engineer_id?: string;
  line_items?: Array<{
    id?: string;
    date: string;
    category: "travel" | "lodging" | "food" | "other";
    amount: number;
    description: string;
  }>;
}

export class ExpenseService {
  /**
   * Create a new expense with line items
   * Automatically computes total amount from line items
   */
  static async createExpense(
    userId: string,
    data: CreateExpenseData
  ): Promise<ExpenseWithLineItems> {
    // Validate line items
    if (!data.line_items || data.line_items.length === 0) {
      throw new Error("At least one line item is required");
    }

    // Validate amounts
    for (const item of data.line_items) {
      if (item.amount <= 0) {
        throw new Error("All line item amounts must be greater than 0");
      }
    }

    // Calculate total amount
    const totalAmount = data.line_items.reduce((sum, item) => sum + item.amount, 0);

    // Start transaction
    const { data: expense, error: expenseError } = await supabase
      .from("expenses")
      .insert({
        user_id: userId,
        title: data.title,
        destination: data.destination,
        trip_start: data.trip_start,
        trip_end: data.trip_end,
        purpose: data.purpose,
        total_amount: totalAmount,
        status: "draft",
      })
      .select()
      .single();

    if (expenseError) {
      console.error("Expense creation error:", expenseError);
      throw new Error(`Failed to create expense: ${expenseError.message || 'Unknown error'}`);
    }

    // Insert line items
    const lineItemsData: LineItemInsert[] = data.line_items.map(item => ({
      expense_id: expense.id,
      date: item.date,
      category: item.category,
      amount: item.amount,
      description: item.description,
    }));

    const { data: lineItems, error: lineItemsError } = await supabase
      .from("expense_line_items")
      .insert(lineItemsData)
      .select();

    if (lineItemsError) {
      console.error("Line items creation error:", lineItemsError);
      throw new Error(`Failed to create line items: ${lineItemsError.message || 'Unknown error'}`);
    }

    // Log the action
    await this.logAction(expense.id, userId, "expense_created", "Expense created");

    return {
      ...expense,
      expense_line_items: lineItems,
    };
  }

  /**
   * Update an existing expense
   * Recalculates total amount if line items are updated
   */
  static async updateExpense(
    expenseId: string,
    userId: string,
    data: UpdateExpenseData
  ): Promise<ExpenseWithLineItems> {
    // Check if user can edit this expense
    const canEdit = await this.canUserEditExpense(expenseId, userId);
    if (!canEdit) {
      throw new Error("You don't have permission to edit this expense");
    }

    // Get current expense
    const { data: currentExpense, error: fetchError } = await supabase
      .from("expenses")
      .select("*")
      .eq("id", expenseId)
      .single();

    if (fetchError) throw fetchError;

    // Check if expense can be edited (only draft status allows editing)
    if (currentExpense.status !== "draft" && !data.status) {
      throw new Error("Only draft expenses can be edited");
    }

    let totalAmount = currentExpense.total_amount;

    // Update line items if provided
    if (data.line_items) {
      // Validate line items
      for (const item of data.line_items) {
        if (item.amount <= 0) {
          throw new Error("All line item amounts must be greater than 0");
        }
      }

      // Delete existing line items
      const { error: deleteError } = await supabase
        .from("expense_line_items")
        .delete()
        .eq("expense_id", expenseId);

      if (deleteError) throw deleteError;

      // Insert new line items
      const lineItemsData: LineItemInsert[] = data.line_items.map(item => ({
        expense_id: expenseId,
        date: item.date,
        category: item.category,
        amount: item.amount,
        description: item.description,
      }));

      const { error: insertError } = await supabase
        .from("expense_line_items")
        .insert(lineItemsData);

      if (insertError) throw insertError;

      // Recalculate total amount
      totalAmount = data.line_items.reduce((sum, item) => sum + item.amount, 0);
    }

    // Update expense
    const updateData: ExpenseUpdate = {
      ...data,
      total_amount: totalAmount,
      updated_at: new Date().toISOString(),
    };

    const { data: updatedExpense, error: updateError } = await supabase
      .from("expenses")
      .update(updateData)
      .eq("id", expenseId)
      .select()
      .single();

    if (updateError) throw updateError;

    // Get updated line items
    const { data: lineItems, error: lineItemsError } = await supabase
      .from("expense_line_items")
      .select("*")
      .eq("expense_id", expenseId);

    if (lineItemsError) throw lineItemsError;

    // Log the action
    const action = data.status ? `status_changed_to_${data.status}` : "expense_updated";
    await this.logAction(expenseId, userId, action, data.admin_comment);

    return {
      ...updatedExpense,
      expense_line_items: lineItems,
    };
  }

  /**
   * Submit an expense for review
   */
  static async submitExpense(expenseId: string, userId: string): Promise<Expense> {
    // Check if user can submit this expense
    const canEdit = await this.canUserEditExpense(expenseId, userId);
    if (!canEdit) {
      throw new Error("You don't have permission to submit this expense");
    }

    // Get current expense
    const { data: expense, error: fetchError } = await supabase
      .from("expenses")
      .select("*")
      .eq("id", expenseId)
      .single();

    if (fetchError) throw fetchError;

    if (expense.status !== "draft") {
      throw new Error("Only draft expenses can be submitted");
    }

    // Check if expense has line items
    const { data: lineItems, error: lineItemsError } = await supabase
      .from("expense_line_items")
      .select("*")
      .eq("expense_id", expenseId);

    if (lineItemsError) throw lineItemsError;

    if (!lineItems || lineItems.length === 0) {
      throw new Error("Cannot submit expense without line items");
    }

    // Update status to submitted
    const { data: updatedExpense, error: updateError } = await supabase
      .from("expenses")
      .update({
        status: "submitted",
        updated_at: new Date().toISOString(),
      })
      .eq("id", expenseId)
      .select()
      .single();

    if (updateError) throw updateError;

    // Log the action
    await this.logAction(expenseId, userId, "expense_submitted", "Expense submitted for review");

    return updatedExpense;
  }

  /**
   * Assign expense to an engineer
   */
  static async assignToEngineer(
    expenseId: string,
    engineerId: string,
    adminId: string
  ): Promise<Expense> {
    // Check if admin has permission
    const isAdmin = await this.hasRole(adminId, "admin");
    if (!isAdmin) {
      throw new Error("Only administrators can assign expenses to engineers");
    }

    // Check if engineer exists and has engineer role
    const isEngineer = await this.hasRole(engineerId, "engineer");
    if (!isEngineer) {
      throw new Error("Assigned user must have engineer role");
    }

    // Update expense
    const { data: updatedExpense, error: updateError } = await supabase
      .from("expenses")
      .update({
        assigned_engineer_id: engineerId,
        status: "under_review",
        updated_at: new Date().toISOString(),
      })
      .eq("id", expenseId)
      .select()
      .single();

    if (updateError) throw updateError;

    // Log the action
    await this.logAction(expenseId, adminId, "expense_assigned", `Assigned to engineer ${engineerId}`);

    return updatedExpense;
  }

  /**
   * Verify expense (engineer action)
   */
  static async verifyExpense(
    expenseId: string,
    engineerId: string,
    verified: boolean,
    comment?: string
  ): Promise<Expense> {
    // Check if engineer has permission
    const canReview = await this.canEngineerReviewExpense(expenseId, engineerId);
    if (!canReview) {
      throw new Error("You don't have permission to review this expense");
    }

    // Update expense status
    const status = verified ? "verified" : "rejected";
    const { data: updatedExpense, error: updateError } = await supabase
      .from("expenses")
      .update({
        status,
        updated_at: new Date().toISOString(),
      })
      .eq("id", expenseId)
      .select()
      .single();

    if (updateError) throw updateError;

    // Log the action
    const action = verified ? "expense_verified" : "expense_rejected_by_engineer";
    await this.logAction(expenseId, engineerId, action, comment);

    return updatedExpense;
  }

  /**
   * Approve expense (admin action)
   */
  static async approveExpense(
    expenseId: string,
    adminId: string,
    comment?: string
  ): Promise<Expense> {
    // Check if admin has permission
    const isAdmin = await this.hasRole(adminId, "admin");
    if (!isAdmin) {
      throw new Error("Only administrators can approve expenses");
    }

    // Update expense
    const { data: updatedExpense, error: updateError } = await supabase
      .from("expenses")
      .update({
        status: "approved",
        admin_comment: comment,
        updated_at: new Date().toISOString(),
      })
      .eq("id", expenseId)
      .select()
      .single();

    if (updateError) throw updateError;

    // Log the action
    await this.logAction(expenseId, adminId, "expense_approved", comment);

    return updatedExpense;
  }

  /**
   * Reject expense (admin action)
   */
  static async rejectExpense(
    expenseId: string,
    adminId: string,
    comment?: string
  ): Promise<Expense> {
    // Check if admin has permission
    const isAdmin = await this.hasRole(adminId, "admin");
    if (!isAdmin) {
      throw new Error("Only administrators can reject expenses");
    }

    // Update expense
    const { data: updatedExpense, error: updateError } = await supabase
      .from("expenses")
      .update({
        status: "rejected",
        admin_comment: comment,
        updated_at: new Date().toISOString(),
      })
      .eq("id", expenseId)
      .select()
      .single();

    if (updateError) throw updateError;

    // Log the action
    await this.logAction(expenseId, adminId, "expense_rejected", comment);

    return updatedExpense;
  }

  /**
   * Get expense with line items
   */
  static async getExpense(expenseId: string): Promise<ExpenseWithLineItems | null> {
    const { data: expense, error: expenseError } = await supabase
      .from("expenses")
      .select("*")
      .eq("id", expenseId)
      .single();

    if (expenseError) return null;

    const { data: lineItems, error: lineItemsError } = await supabase
      .from("expense_line_items")
      .select("*")
      .eq("expense_id", expenseId);

    if (lineItemsError) return null;

    return {
      ...expense,
      expense_line_items: lineItems || [],
    };
  }

  /**
   * Check if user can edit expense
   */
  private static async canUserEditExpense(expenseId: string, userId: string): Promise<boolean> {
    // Check if user is admin
    const isAdmin = await this.hasRole(userId, "admin");
    if (isAdmin) return true;

    // Check if user owns the expense
    const { data: expense, error } = await supabase
      .from("expenses")
      .select("user_id, status")
      .eq("id", expenseId)
      .single();

    if (error) return false;

    return expense.user_id === userId && expense.status === "draft";
  }

  /**
   * Check if engineer can review expense
   */
  private static async canEngineerReviewExpense(expenseId: string, engineerId: string): Promise<boolean> {
    const { data: expense, error } = await supabase
      .from("expenses")
      .select("assigned_engineer_id")
      .eq("id", expenseId)
      .single();

    if (error) return false;

    return expense.assigned_engineer_id === engineerId;
  }

  /**
   * Check if user has specific role
   */
  private static async hasRole(userId: string, role: "admin" | "engineer" | "employee"): Promise<boolean> {
    const { data, error } = await supabase
      .from("user_roles")
      .select("role")
      .eq("user_id", userId)
      .eq("role", role)
      .maybeSingle();

    if (error) return false;

    return !!data;
  }

  /**
   * Log action in audit trail
   */
  private static async logAction(
    expenseId: string,
    userId: string,
    action: string,
    comment?: string
  ): Promise<void> {
    await supabase
      .from("audit_logs")
      .insert({
        expense_id: expenseId,
        user_id: userId,
        action,
        comment,
      });
  }
}
