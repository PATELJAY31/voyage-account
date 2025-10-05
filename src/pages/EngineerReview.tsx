import { useEffect, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import { 
  Receipt, 
  CheckCircle, 
  XCircle, 
  Clock, 
  DollarSign,
  Eye,
  FileText,
  User
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { format } from "date-fns";
import { StatusBadge } from "@/components/StatusBadge";

interface Expense {
  id: string;
  title: string;
  destination: string;
  trip_start: string;
  trip_end: string;
  status: string;
  total_amount: number;
  created_at: string;
  user_id: string;
  user_name: string;
  user_email: string;
  purpose?: string;
  admin_comment?: string;
}

interface LineItem {
  id: string;
  date: string;
  category: string;
  amount: number;
  description: string;
}

interface Attachment {
  id: string;
  filename: string;
  content_type: string;
  file_url: string;
  created_at: string;
}

export default function EngineerReview() {
  const { user, userRole } = useAuth();
  const { toast } = useToast();
  
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedExpense, setSelectedExpense] = useState<Expense | null>(null);
  const [lineItems, setLineItems] = useState<LineItem[]>([]);
  const [attachments, setAttachments] = useState<Attachment[]>([]);
  const [engineerComment, setEngineerComment] = useState("");
  const [reviewLoading, setReviewLoading] = useState(false);

  useEffect(() => {
    if (userRole === "engineer") {
      fetchAssignedExpenses();
    }
  }, [userRole, user]);

  const fetchAssignedExpenses = async () => {
    try {
      setLoading(true);
      
      const { data, error } = await supabase
        .from("expenses")
        .select(`
          *,
          profiles!inner(name, email)
        `)
        .eq("assigned_engineer_id", user?.id)
        .in("status", ["under_review", "verified"])
        .order("created_at", { ascending: false });

      if (error) throw error;

      setExpenses(data.map(expense => ({
        ...expense,
        user_name: expense.profiles.name,
        user_email: expense.profiles.email,
        total_amount: Number(expense.total_amount)
      })));
    } catch (error) {
      console.error("Error fetching assigned expenses:", error);
    } finally {
      setLoading(false);
    }
  };

  const fetchExpenseDetails = async (expenseId: string) => {
    try {
      // Fetch line items
      const { data: lineItemsData, error: lineItemsError } = await supabase
        .from("expense_line_items")
        .select("*")
        .eq("expense_id", expenseId)
        .order("date");

      if (lineItemsError) throw lineItemsError;

      // Fetch attachments
      const { data: attachmentsData, error: attachmentsError } = await supabase
        .from("attachments")
        .select("*")
        .eq("expense_id", expenseId)
        .order("created_at");

      if (attachmentsError) throw attachmentsError;

      setLineItems(lineItemsData || []);
      setAttachments(attachmentsData || []);
    } catch (error) {
      console.error("Error fetching expense details:", error);
    }
  };

  const updateExpenseStatus = async (status: "verified" | "rejected") => {
    if (!selectedExpense) return;

    try {
      setReviewLoading(true);

      const { error } = await supabase
        .from("expenses")
        .update({
          status,
          updated_at: new Date().toISOString()
        })
        .eq("id", selectedExpense.id);

      if (error) throw error;

      // Log the action
      await supabase
        .from("audit_logs")
        .insert({
          expense_id: selectedExpense.id,
          user_id: user?.id,
          action: `Engineer ${status} expense`,
          comment: engineerComment || null
        });

      toast({
        title: "Success",
        description: `Expense ${status} successfully`,
      });

      setSelectedExpense(null);
      setEngineerComment("");
      setLineItems([]);
      setAttachments([]);
      fetchAssignedExpenses();
    } catch (error: any) {
      console.error("Error updating expense:", error);
      toast({
        variant: "destructive",
        title: "Error",
        description: error.message || "Failed to update expense",
      });
    } finally {
      setReviewLoading(false);
    }
  };

  const getStats = () => {
    const totalAssigned = expenses.length;
    const pendingReview = expenses.filter(e => e.status === "under_review").length;
    const verified = expenses.filter(e => e.status === "verified").length;
    const totalAmount = expenses.reduce((sum, e) => sum + e.total_amount, 0);

    return {
      totalAssigned,
      pendingReview,
      verified,
      totalAmount
    };
  };

  const stats = getStats();

  if (userRole !== "engineer") {
    return (
      <div className="space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold tracking-tight">Access Denied</h1>
          <p className="text-muted-foreground">You don't have permission to access this page.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Expense Review</h1>
          <p className="text-muted-foreground">
            Review and verify assigned expense submissions
          </p>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Assigned to Me</CardTitle>
            <Receipt className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.totalAssigned}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Pending Review</CardTitle>
            <Clock className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.pendingReview}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Verified</CardTitle>
            <CheckCircle className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{stats.verified}</div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
            <CardTitle className="text-sm font-medium">Total Amount</CardTitle>
            <DollarSign className="h-4 w-4 text-muted-foreground" />
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">${stats.totalAmount.toFixed(2)}</div>
          </CardContent>
        </Card>
      </div>

      {/* Expenses Table */}
      <Card>
        <CardHeader>
          <CardTitle>Assigned Expenses</CardTitle>
          <CardDescription>Review and verify expense submissions assigned to you</CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <p className="text-muted-foreground">Loading...</p>
          ) : expenses.length === 0 ? (
            <div className="text-center py-8">
              <Receipt className="h-12 w-12 mx-auto text-muted-foreground mb-4" />
              <h3 className="text-lg font-medium">No assigned expenses</h3>
              <p className="text-muted-foreground">
                You don't have any expenses assigned for review at the moment.
              </p>
            </div>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Employee</TableHead>
                  <TableHead>Title</TableHead>
                  <TableHead>Destination</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Created</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {expenses.map((expense) => (
                  <TableRow key={expense.id}>
                    <TableCell>
                      <div>
                        <div className="font-medium">{expense.user_name}</div>
                        <div className="text-sm text-muted-foreground">{expense.user_email}</div>
                      </div>
                    </TableCell>
                    <TableCell className="font-medium">{expense.title}</TableCell>
                    <TableCell>{expense.destination}</TableCell>
                    <TableCell>${expense.total_amount.toFixed(2)}</TableCell>
                    <TableCell>
                      <StatusBadge status={expense.status as any} />
                    </TableCell>
                    <TableCell>
                      {format(new Date(expense.created_at), "MMM d, yyyy")}
                    </TableCell>
                    <TableCell className="text-right">
                      <Dialog>
                        <DialogTrigger asChild>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => {
                              setSelectedExpense(expense);
                              fetchExpenseDetails(expense.id);
                            }}
                          >
                            <Eye className="h-4 w-4" />
                          </Button>
                        </DialogTrigger>
                        <DialogContent className="max-w-4xl max-h-[90vh] overflow-y-auto">
                          <DialogHeader>
                            <DialogTitle>Expense Review</DialogTitle>
                            <DialogDescription>
                              Review expense details and verify the submission
                            </DialogDescription>
                          </DialogHeader>
                          
                          {selectedExpense && (
                            <div className="space-y-6">
                              {/* Basic Info */}
                              <div className="grid grid-cols-2 gap-4">
                                <Card>
                                  <CardHeader className="pb-3">
                                    <CardTitle className="text-base">Employee Information</CardTitle>
                                  </CardHeader>
                                  <CardContent>
                                    <div className="space-y-2">
                                      <div className="flex items-center gap-2">
                                        <User className="h-4 w-4 text-muted-foreground" />
                                        <span className="font-medium">{selectedExpense.user_name}</span>
                                      </div>
                                      <div className="text-sm text-muted-foreground">
                                        {selectedExpense.user_email}
                                      </div>
                                    </div>
                                  </CardContent>
                                </Card>

                                <Card>
                                  <CardHeader className="pb-3">
                                    <CardTitle className="text-base">Expense Summary</CardTitle>
                                  </CardHeader>
                                  <CardContent>
                                    <div className="space-y-2">
                                      <div className="flex items-center gap-2">
                                        <DollarSign className="h-4 w-4 text-muted-foreground" />
                                        <span className="text-lg font-semibold">
                                          ${selectedExpense.total_amount.toFixed(2)}
                                        </span>
                                      </div>
                                      <div className="flex items-center gap-2">
                                        <StatusBadge status={selectedExpense.status as any} />
                                      </div>
                                    </div>
                                  </CardContent>
                                </Card>
                              </div>

                              {/* Trip Details */}
                              <Card>
                                <CardHeader className="pb-3">
                                  <CardTitle className="text-base">Trip Details</CardTitle>
                                </CardHeader>
                                <CardContent className="space-y-3">
                                  <div>
                                    <label className="text-sm font-medium">Title</label>
                                    <p className="text-sm">{selectedExpense.title}</p>
                                  </div>
                                  <div>
                                    <label className="text-sm font-medium">Destination</label>
                                    <p className="text-sm">{selectedExpense.destination}</p>
                                  </div>
                                  <div className="grid grid-cols-2 gap-4">
                                    <div>
                                      <label className="text-sm font-medium">Start Date</label>
                                      <p className="text-sm">{format(new Date(selectedExpense.trip_start), "MMM d, yyyy")}</p>
                                    </div>
                                    <div>
                                      <label className="text-sm font-medium">End Date</label>
                                      <p className="text-sm">{format(new Date(selectedExpense.trip_end), "MMM d, yyyy")}</p>
                                    </div>
                                  </div>
                                  {selectedExpense.purpose && (
                                    <div>
                                      <label className="text-sm font-medium">Purpose</label>
                                      <p className="text-sm">{selectedExpense.purpose}</p>
                                    </div>
                                  )}
                                </CardContent>
                              </Card>

                              {/* Line Items */}
                              <Card>
                                <CardHeader className="pb-3">
                                  <CardTitle className="text-base flex items-center gap-2">
                                    <FileText className="h-4 w-4" />
                                    Expense Line Items
                                  </CardTitle>
                                </CardHeader>
                                <CardContent>
                                  {lineItems.length === 0 ? (
                                    <p className="text-muted-foreground">No line items found</p>
                                  ) : (
                                    <Table>
                                      <TableHeader>
                                        <TableRow>
                                          <TableHead>Date</TableHead>
                                          <TableHead>Category</TableHead>
                                          <TableHead>Description</TableHead>
                                          <TableHead className="text-right">Amount</TableHead>
                                        </TableRow>
                                      </TableHeader>
                                      <TableBody>
                                        {lineItems.map((item) => (
                                          <TableRow key={item.id}>
                                            <TableCell>
                                              {format(new Date(item.date), "MMM d, yyyy")}
                                            </TableCell>
                                            <TableCell>
                                              <Badge variant="outline" className="capitalize">
                                                {item.category}
                                              </Badge>
                                            </TableCell>
                                            <TableCell>{item.description}</TableCell>
                                            <TableCell className="text-right">
                                              ${item.amount.toFixed(2)}
                                            </TableCell>
                                          </TableRow>
                                        ))}
                                      </TableBody>
                                    </Table>
                                  )}
                                </CardContent>
                              </Card>

                              {/* Attachments */}
                              {attachments.length > 0 && (
                                <Card>
                                  <CardHeader className="pb-3">
                                    <CardTitle className="text-base">Receipts & Attachments</CardTitle>
                                  </CardHeader>
                                  <CardContent>
                                    <div className="space-y-2">
                                      {attachments.map((attachment) => (
                                        <div
                                          key={attachment.id}
                                          className="flex items-center justify-between p-3 border rounded-lg"
                                        >
                                          <div className="flex items-center gap-3">
                                            <FileText className="h-4 w-4 text-muted-foreground" />
                                            <div>
                                              <p className="font-medium text-sm">{attachment.filename}</p>
                                              <p className="text-xs text-muted-foreground">
                                                {attachment.content_type} • {format(new Date(attachment.created_at), "MMM d, yyyy")}
                                              </p>
                                            </div>
                                          </div>
                                          <Button
                                            variant="outline"
                                            size="sm"
                                            onClick={() => window.open(attachment.file_url, '_blank')}
                                          >
                                            View
                                          </Button>
                                        </div>
                                      ))}
                                    </div>
                                  </CardContent>
                                </Card>
                              )}

                              {/* Admin Comments */}
                              {selectedExpense.admin_comment && (
                                <Card>
                                  <CardHeader className="pb-3">
                                    <CardTitle className="text-base">Admin Comments</CardTitle>
                                  </CardHeader>
                                  <CardContent>
                                    <p className="text-sm">{selectedExpense.admin_comment}</p>
                                  </CardContent>
                                </Card>
                              )}

                              {/* Engineer Review */}
                              <Card>
                                <CardHeader className="pb-3">
                                  <CardTitle className="text-base">Engineer Review</CardTitle>
                                </CardHeader>
                                <CardContent className="space-y-4">
                                  <div>
                                    <label className="text-sm font-medium">Review Comment</label>
                                    <Textarea
                                      value={engineerComment}
                                      onChange={(e) => setEngineerComment(e.target.value)}
                                      placeholder="Add your review comments..."
                                      className="mt-1"
                                    />
                                  </div>
                                </CardContent>
                              </Card>
                            </div>
                          )}

                          <DialogFooter className="gap-2">
                            <Button 
                              variant="outline" 
                              onClick={() => {
                                setSelectedExpense(null);
                                setEngineerComment("");
                                setLineItems([]);
                                setAttachments([]);
                              }}
                            >
                              Cancel
                            </Button>
                            <Button 
                              variant="destructive"
                              onClick={() => updateExpenseStatus("rejected")}
                              disabled={reviewLoading}
                            >
                              <XCircle className="mr-2 h-4 w-4" />
                              Reject
                            </Button>
                            <Button 
                              onClick={() => updateExpenseStatus("verified")}
                              disabled={reviewLoading}
                            >
                              <CheckCircle className="mr-2 h-4 w-4" />
                              Verify
                            </Button>
                          </DialogFooter>
                        </DialogContent>
                      </Dialog>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
