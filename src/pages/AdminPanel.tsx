import { useEffect, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Textarea } from "@/components/ui/textarea";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { 
  Table, 
  TableBody, 
  TableCell, 
  TableHead, 
  TableHeader, 
  TableRow 
} from "@/components/ui/table";
import { 
  Users, 
  Receipt, 
  CheckCircle, 
  XCircle, 
  Clock, 
  DollarSign,
  Eye,
  UserPlus,
  Settings,
  TrendingUp,
  Filter,
  Search,
  Download
} from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { ExpenseService } from "@/services/ExpenseService";
import { format } from "date-fns";
import { StatusBadge } from "@/components/StatusBadge";
import { Input } from "@/components/ui/input";

interface User {
  id: string;
  email: string;
  name: string;
  role: string;
  created_at: string;
  is_active: boolean;
}

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
  assigned_engineer_id?: string;
  admin_comment?: string;
}

export default function AdminPanel() {
  const { userRole } = useAuth();
  const { toast } = useToast();
  
  const [users, setUsers] = useState<User[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedExpense, setSelectedExpense] = useState<Expense | null>(null);
  const [adminComment, setAdminComment] = useState("");
  const [selectedStatus, setSelectedStatus] = useState("");
  const [selectedEngineer, setSelectedEngineer] = useState("");
  const [engineers, setEngineers] = useState<User[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [statusFilter, setStatusFilter] = useState<string>("all");

  useEffect(() => {
    if (userRole === "admin") {
      fetchData();
    }
  }, [userRole]);

  const fetchData = async () => {
    try {
      setLoading(true);
      await Promise.all([
        fetchUsers(),
        fetchExpenses(),
        fetchEngineers()
      ]);
    } catch (error) {
      console.error("Error fetching data:", error);
    } finally {
      setLoading(false);
    }
  };

  const fetchUsers = async () => {
    const { data, error } = await supabase
      .from("profiles")
      .select(`
        id,
        user_id,
        name,
        email,
        created_at,
        is_active,
        user_roles!inner(role)
      `)
      .order("created_at", { ascending: false });

    if (error) throw error;

    setUsers(data.map(user => ({
      id: user.user_id,
      email: user.email,
      name: user.name,
      role: user.user_roles[0]?.role || "employee",
      created_at: user.created_at,
      is_active: user.is_active
    })));
  };

  const fetchExpenses = async () => {
    console.log("Fetching expenses for admin...");
    
    // First, let's check the current user's role
    const { data: currentUser } = await supabase.auth.getUser();
    console.log("Current user:", currentUser.user?.id);
    
    // Check user roles
    const { data: userRoles, error: roleError } = await supabase
      .from("user_roles")
      .select("*")
      .eq("user_id", currentUser.user?.id);
    
    console.log("User roles:", userRoles, "Error:", roleError);
    
    const { data, error } = await supabase
      .from("expenses")
      .select(`
        *,
        profiles!inner(name, email)
      `)
      .order("created_at", { ascending: false });

    console.log("Expenses query result:", { data, error });

    if (error) {
      console.error("Error fetching expenses:", error);
      throw error;
    }

    setExpenses(data.map(expense => ({
      ...expense,
      user_name: expense.profiles.name,
      user_email: expense.profiles.email,
      total_amount: Number(expense.total_amount)
    })));
  };

  const fetchEngineers = async () => {
    const { data, error } = await supabase
      .from("user_roles")
      .select(`
        user_id,
        profiles!inner(name, email)
      `)
      .eq("role", "engineer");

    if (error) throw error;

    setEngineers(data.map(item => ({
      id: item.user_id,
      email: item.profiles.email,
      name: item.profiles.name,
      role: "engineer",
      created_at: "",
      is_active: true
    })));
  };

  const approveExpense = async () => {
    if (!selectedExpense || !user) return;

    try {
      await ExpenseService.approveExpense(selectedExpense.id, user.id, adminComment);
      
      toast({
        title: "Expense Approved",
        description: "The expense has been approved successfully",
      });

      setSelectedExpense(null);
      setAdminComment("");
      fetchExpenses();
    } catch (error: any) {
      toast({
        variant: "destructive",
        title: "Error",
        description: error.message || "Failed to approve expense",
      });
    }
  };

  const rejectExpense = async () => {
    if (!selectedExpense || !user) return;

    try {
      await ExpenseService.rejectExpense(selectedExpense.id, user.id, adminComment);
      
      toast({
        title: "Expense Rejected",
        description: "The expense has been rejected",
      });

      setSelectedExpense(null);
      setAdminComment("");
      fetchExpenses();
    } catch (error: any) {
      toast({
        variant: "destructive",
        title: "Error",
        description: error.message || "Failed to reject expense",
      });
    }
  };

  const assignToEngineer = async () => {
    if (!selectedExpense || !selectedEngineer || !user) return;

    try {
      await ExpenseService.assignToEngineer(selectedExpense.id, selectedEngineer, user.id);
      
      toast({
        title: "Expense Assigned",
        description: "The expense has been assigned to an engineer for review",
      });

      setSelectedExpense(null);
      setSelectedEngineer("");
      fetchExpenses();
    } catch (error: any) {
      toast({
        variant: "destructive",
        title: "Error",
        description: error.message || "Failed to assign expense",
      });
    }
  };

  const updateExpenseStatus = async () => {
    if (!selectedExpense || !selectedStatus) return;

    try {
      const updateData: any = {
        status: selectedStatus,
        updated_at: new Date().toISOString()
      };

      if (selectedEngineer) {
        updateData.assigned_engineer_id = selectedEngineer;
      }

      if (adminComment) {
        updateData.admin_comment = adminComment;
      }

      const { error } = await supabase
        .from("expenses")
        .update(updateData)
        .eq("id", selectedExpense.id);

      if (error) throw error;

      // Log the action
      await supabase
        .from("audit_logs")
        .insert({
          expense_id: selectedExpense.id,
          user_id: (await supabase.auth.getUser()).data.user?.id,
          action: `Status changed to ${selectedStatus}`,
          comment: adminComment || null
        });

      toast({
        title: "Success",
        description: "Expense status updated successfully",
      });

      setSelectedExpense(null);
      setAdminComment("");
      setSelectedStatus("");
      setSelectedEngineer("");
      fetchExpenses();
    } catch (error: any) {
      console.error("Error updating expense:", error);
      toast({
        variant: "destructive",
        title: "Error",
        description: error.message || "Failed to update expense",
      });
    }
  };

  const updateUserRole = async (userId: string, newRole: string) => {
    try {
      const { error } = await supabase
        .from("user_roles")
        .upsert({
          user_id: userId,
          role: newRole
        });

      if (error) throw error;

      toast({
        title: "Success",
        description: "User role updated successfully",
      });

      fetchUsers();
    } catch (error: any) {
      console.error("Error updating user role:", error);
      toast({
        variant: "destructive",
        title: "Error",
        description: error.message || "Failed to update user role",
      });
    }
  };

  // Filter and search functions
  const filteredExpenses = expenses.filter(expense => {
    const matchesSearch = searchTerm === "" || 
      expense.title.toLowerCase().includes(searchTerm.toLowerCase()) ||
      expense.destination.toLowerCase().includes(searchTerm.toLowerCase()) ||
      expense.user_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
      expense.user_email.toLowerCase().includes(searchTerm.toLowerCase());
    
    const matchesStatus = statusFilter === "all" || expense.status === statusFilter;
    
    return matchesSearch && matchesStatus;
  });

  const exportExpenses = () => {
    const csvContent = [
      ["Employee", "Email", "Title", "Destination", "Amount", "Status", "Created Date"],
      ...filteredExpenses.map(expense => [
        expense.user_name,
        expense.user_email,
        expense.title,
        expense.destination,
        `$${expense.total_amount.toFixed(2)}`,
        expense.status,
        format(new Date(expense.created_at), "MMM d, yyyy")
      ])
    ].map(row => row.join(",")).join("\n");

    const blob = new Blob([csvContent], { type: "text/csv" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `expenses-${format(new Date(), "yyyy-MM-dd")}.csv`;
    a.click();
    window.URL.revokeObjectURL(url);
  };

  const assignAdminRole = async () => {
    try {
      const { data: currentUser } = await supabase.auth.getUser();
      if (!currentUser.user) return;

      // Check if user already has admin role
      const { data: existingRoles } = await supabase
        .from("user_roles")
        .select("*")
        .eq("user_id", currentUser.user.id);

      if (existingRoles && existingRoles.some(role => role.role === "admin")) {
        toast({
          title: "Admin Role Already Assigned",
          description: "You already have admin privileges. Checking access...",
        });
        fetchData();
        return;
      }

      const { error } = await supabase
        .from("user_roles")
        .upsert({
          user_id: currentUser.user.id,
          role: "admin",
        });

      if (error) throw error;

      toast({
        title: "Admin Role Assigned",
        description: "You now have admin privileges",
      });

      fetchData();
    } catch (error: any) {
      console.error("Error assigning admin role:", error);
      if (error.code === "23505") {
        toast({
          title: "Admin Role Already Exists",
          description: "You already have admin privileges. Refreshing data...",
        });
        fetchData();
      } else {
        toast({
          variant: "destructive",
          title: "Error",
          description: error.message || "Failed to assign admin role",
        });
      }
    }
  };

  const getStats = () => {
    const totalExpenses = expenses.length;
    const pendingExpenses = expenses.filter(e => ["submitted", "under_review", "verified"].includes(e.status)).length;
    const approvedExpenses = expenses.filter(e => ["approved", "paid"].includes(e.status)).length;
    const totalAmount = expenses.reduce((sum, e) => sum + e.total_amount, 0);

    return {
      totalExpenses,
      pendingExpenses,
      approvedExpenses,
      totalAmount,
      totalUsers: users.length
    };
  };

  const stats = getStats();

  if (userRole !== "admin") {
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
      {/* Header Section */}
      <div className="text-center space-y-4">
        <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-r from-purple-600 to-pink-600 rounded-2xl shadow-lg">
          <Settings className="h-8 w-8 text-white" />
        </div>
        <h1 className="text-4xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 bg-clip-text text-transparent">
          Admin Panel
        </h1>
        <p className="text-lg text-gray-600 max-w-2xl mx-auto">
          Manage users, expenses, and system settings with comprehensive oversight
        </p>
        
        {/* Debug: Assign Admin Role Button */}
        <div className="mt-4 space-x-2">
          <Button 
            onClick={assignAdminRole}
            variant="outline"
            className="bg-yellow-50 border-yellow-200 text-yellow-800 hover:bg-yellow-100"
          >
            🔧 Debug: Assign Admin Role
          </Button>
          <Button 
            onClick={() => {
              console.log("=== DEBUG INFO ===");
              console.log("Current user role:", userRole);
              console.log("Expenses count:", expenses.length);
              console.log("Filtered expenses count:", filteredExpenses.length);
              console.log("Loading state:", loading);
            }}
            variant="outline"
            className="bg-blue-50 border-blue-200 text-blue-800 hover:bg-blue-100"
          >
            🔍 Debug: Check Status
          </Button>
        </div>
      </div>

      {/* Stats Cards */}
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-5">
        <Card className="shadow-xl border-0 bg-white/80 backdrop-blur-sm hover:shadow-2xl transition-all duration-300">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="space-y-2">
                <p className="text-sm font-medium text-gray-600">Total Users</p>
                <p className="text-2xl font-bold text-gray-900">{stats.totalUsers}</p>
              </div>
              <div className="w-12 h-12 bg-gradient-to-r from-blue-500 to-blue-600 rounded-xl flex items-center justify-center shadow-lg">
                <Users className="h-6 w-6 text-white" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-xl border-0 bg-white/80 backdrop-blur-sm hover:shadow-2xl transition-all duration-300">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="space-y-2">
                <p className="text-sm font-medium text-gray-600">Total Expenses</p>
                <p className="text-2xl font-bold text-gray-900">{stats.totalExpenses}</p>
              </div>
              <div className="w-12 h-12 bg-gradient-to-r from-emerald-500 to-emerald-600 rounded-xl flex items-center justify-center shadow-lg">
                <Receipt className="h-6 w-6 text-white" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-xl border-0 bg-white/80 backdrop-blur-sm hover:shadow-2xl transition-all duration-300">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="space-y-2">
                <p className="text-sm font-medium text-gray-600">Pending</p>
                <p className="text-2xl font-bold text-gray-900">{stats.pendingExpenses}</p>
              </div>
              <div className="w-12 h-12 bg-gradient-to-r from-yellow-500 to-orange-500 rounded-xl flex items-center justify-center shadow-lg">
                <Clock className="h-6 w-6 text-white" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-xl border-0 bg-white/80 backdrop-blur-sm hover:shadow-2xl transition-all duration-300">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="space-y-2">
                <p className="text-sm font-medium text-gray-600">Approved</p>
                <p className="text-2xl font-bold text-gray-900">{stats.approvedExpenses}</p>
              </div>
              <div className="w-12 h-12 bg-gradient-to-r from-green-500 to-emerald-500 rounded-xl flex items-center justify-center shadow-lg">
                <CheckCircle className="h-6 w-6 text-white" />
              </div>
            </div>
          </CardContent>
        </Card>

        <Card className="shadow-xl border-0 bg-white/80 backdrop-blur-sm hover:shadow-2xl transition-all duration-300">
          <CardContent className="p-6">
            <div className="flex items-center justify-between">
              <div className="space-y-2">
                <p className="text-sm font-medium text-gray-600">Total Amount</p>
                <p className="text-2xl font-bold text-gray-900">${stats.totalAmount.toFixed(2)}</p>
              </div>
              <div className="w-12 h-12 bg-gradient-to-r from-purple-500 to-purple-600 rounded-xl flex items-center justify-center shadow-lg">
                <DollarSign className="h-6 w-6 text-white" />
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Content */}
      <Tabs defaultValue="expenses" className="space-y-4">
        <TabsList>
          <TabsTrigger value="expenses">All Expenses</TabsTrigger>
          <TabsTrigger value="users">User Management</TabsTrigger>
        </TabsList>

        <TabsContent value="expenses" className="space-y-4">
          {/* Search and Filter Controls */}
          <Card className="shadow-xl border-0 bg-white/80 backdrop-blur-sm">
            <CardHeader className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white p-6">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-white/20 rounded-lg flex items-center justify-center">
                  <Filter className="h-5 w-5" />
                </div>
                <div>
                  <CardTitle className="text-xl font-bold">Search & Filter Expenses</CardTitle>
                  <CardDescription className="text-blue-100">Find and filter expenses by various criteria</CardDescription>
                </div>
              </div>
            </CardHeader>
            <CardContent className="p-6">
              <div className="grid gap-4 md:grid-cols-3">
                <div className="space-y-2">
                  <label className="text-sm font-medium text-gray-700">Search</label>
                  <div className="relative">
                    <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
                    <Input
                      placeholder="Search by title, destination, employee..."
                      value={searchTerm}
                      onChange={(e) => setSearchTerm(e.target.value)}
                      className="pl-10 h-12 border-gray-200 focus:border-blue-500 focus:ring-blue-500/20"
                    />
                  </div>
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium text-gray-700">Status Filter</label>
                  <Select value={statusFilter} onValueChange={setStatusFilter}>
                    <SelectTrigger className="h-12 border-gray-200 focus:border-blue-500 focus:ring-blue-500/20">
                      <SelectValue placeholder="All Statuses" />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="all">All Statuses</SelectItem>
                      <SelectItem value="draft">Draft</SelectItem>
                      <SelectItem value="submitted">Submitted</SelectItem>
                      <SelectItem value="under_review">Under Review</SelectItem>
                      <SelectItem value="verified">Verified</SelectItem>
                      <SelectItem value="approved">Approved</SelectItem>
                      <SelectItem value="rejected">Rejected</SelectItem>
                      <SelectItem value="paid">Paid</SelectItem>
                    </SelectContent>
                  </Select>
                </div>
                
                <div className="space-y-2">
                  <label className="text-sm font-medium text-gray-700">Actions</label>
                  <Button 
                    onClick={exportExpenses}
                    className="w-full h-12 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white"
                  >
                    <Download className="h-4 w-4 mr-2" />
                    Export CSV
                  </Button>
                </div>
              </div>
              
              <div className="mt-4 text-sm text-gray-600">
                Showing {filteredExpenses.length} of {expenses.length} expenses
              </div>
            </CardContent>
          </Card>

          <Card className="shadow-xl border-0 bg-white/80 backdrop-blur-sm">
            <CardHeader>
              <CardTitle className="text-xl font-bold">All Expenses</CardTitle>
              <CardDescription>Review and manage expense submissions from all users</CardDescription>
            </CardHeader>
            <CardContent>
              {loading ? (
                <div className="flex items-center justify-center py-8">
                  <div className="w-8 h-8 border-2 border-blue-600 border-t-transparent rounded-full animate-spin"></div>
                  <span className="ml-2 text-gray-600">Loading expenses...</span>
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <Table>
                    <TableHeader>
                      <TableRow className="border-gray-200">
                        <TableHead className="font-semibold">Employee</TableHead>
                        <TableHead className="font-semibold">Title</TableHead>
                        <TableHead className="font-semibold">Destination</TableHead>
                        <TableHead className="font-semibold">Amount</TableHead>
                        <TableHead className="font-semibold">Status</TableHead>
                        <TableHead className="font-semibold">Created</TableHead>
                        <TableHead className="text-right font-semibold">Actions</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filteredExpenses.map((expense) => (
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
                                onClick={() => setSelectedExpense(expense)}
                              >
                                <Eye className="h-4 w-4" />
                              </Button>
                            </DialogTrigger>
                            <DialogContent className="max-w-2xl">
                              <DialogHeader>
                                <DialogTitle>Expense Details</DialogTitle>
                                <DialogDescription>
                                  Review and manage this expense submission
                                </DialogDescription>
                              </DialogHeader>
                              
                              {selectedExpense && (
                                <div className="space-y-4">
                                  <div className="grid grid-cols-2 gap-4">
                                    <div>
                                      <label className="text-sm font-medium">Employee</label>
                                      <p className="text-sm">{selectedExpense.user_name}</p>
                                      <p className="text-xs text-muted-foreground">{selectedExpense.user_email}</p>
                                    </div>
                                    <div>
                                      <label className="text-sm font-medium">Amount</label>
                                      <p className="text-lg font-semibold">${selectedExpense.total_amount.toFixed(2)}</p>
                                    </div>
                                  </div>

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
                                      <label className="text-sm font-medium">Trip Start</label>
                                      <p className="text-sm">{format(new Date(selectedExpense.trip_start), "MMM d, yyyy")}</p>
                                    </div>
                                    <div>
                                      <label className="text-sm font-medium">Trip End</label>
                                      <p className="text-sm">{format(new Date(selectedExpense.trip_end), "MMM d, yyyy")}</p>
                                    </div>
                                  </div>

                                  <div>
                                    <label className="text-sm font-medium">Current Status</label>
                                    <div className="mt-1">
                                      <StatusBadge status={selectedExpense.status as any} />
                                    </div>
                                  </div>

                                  <div>
                                    <label className="text-sm font-medium">Update Status</label>
                                    <Select value={selectedStatus} onValueChange={setSelectedStatus}>
                                      <SelectTrigger className="mt-1">
                                        <SelectValue placeholder="Select new status" />
                                      </SelectTrigger>
                                      <SelectContent>
                                        <SelectItem value="submitted">Submitted</SelectItem>
                                        <SelectItem value="under_review">Under Review</SelectItem>
                                        <SelectItem value="verified">Verified</SelectItem>
                                        <SelectItem value="approved">Approved</SelectItem>
                                        <SelectItem value="rejected">Rejected</SelectItem>
                                        <SelectItem value="paid">Paid</SelectItem>
                                      </SelectContent>
                                    </Select>
                                  </div>

                                  <div>
                                    <label className="text-sm font-medium">Assign Engineer</label>
                                    <Select value={selectedEngineer} onValueChange={setSelectedEngineer}>
                                      <SelectTrigger className="mt-1">
                                        <SelectValue placeholder="Select engineer (optional)" />
                                      </SelectTrigger>
                                      <SelectContent>
                                        <SelectItem value="">No assignment</SelectItem>
                                        {engineers.map((engineer) => (
                                          <SelectItem key={engineer.id} value={engineer.id}>
                                            {engineer.name}
                                          </SelectItem>
                                        ))}
                                      </SelectContent>
                                    </Select>
                                  </div>

                                  <div>
                                    <label className="text-sm font-medium">Admin Comment</label>
                                    <Textarea
                                      value={adminComment}
                                      onChange={(e) => setAdminComment(e.target.value)}
                                      placeholder="Add a comment about this expense..."
                                      className="mt-1"
                                    />
                                  </div>
                                </div>
                              )}

                              <DialogFooter>
                                <Button variant="outline" onClick={() => setSelectedExpense(null)}>
                                  Cancel
                                </Button>
                                <Button onClick={updateExpenseStatus} disabled={!selectedStatus}>
                                  Update Status
                                </Button>
                              </DialogFooter>
                            </DialogContent>
                          </Dialog>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        <TabsContent value="users" className="space-y-4">
          <Card>
            <CardHeader>
              <CardTitle>User Management</CardTitle>
              <CardDescription>Manage user roles and permissions</CardDescription>
            </CardHeader>
            <CardContent>
              {loading ? (
                <p className="text-muted-foreground">Loading...</p>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Name</TableHead>
                      <TableHead>Email</TableHead>
                      <TableHead>Role</TableHead>
                      <TableHead>Status</TableHead>
                      <TableHead>Joined</TableHead>
                      <TableHead className="text-right">Actions</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {users.map((user) => (
                      <TableRow key={user.id}>
                        <TableCell className="font-medium">{user.name}</TableCell>
                        <TableCell>{user.email}</TableCell>
                        <TableCell>
                          <Badge variant={user.role === "admin" ? "default" : "secondary"}>
                            {user.role}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          <Badge variant={user.is_active ? "success" : "destructive"}>
                            {user.is_active ? "Active" : "Inactive"}
                          </Badge>
                        </TableCell>
                        <TableCell>
                          {format(new Date(user.created_at), "MMM d, yyyy")}
                        </TableCell>
                        <TableCell className="text-right">
                          <Select
                            value={user.role}
                            onValueChange={(newRole) => updateUserRole(user.id, newRole)}
                          >
                            <SelectTrigger className="w-32">
                              <SelectValue />
                            </SelectTrigger>
                            <SelectContent>
                              <SelectItem value="employee">Employee</SelectItem>
                              <SelectItem value="engineer">Engineer</SelectItem>
                              <SelectItem value="admin">Admin</SelectItem>
                            </SelectContent>
                          </Select>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
