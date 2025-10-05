import { useEffect, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Plus } from "lucide-react";
import { useNavigate } from "react-router-dom";
import { StatusBadge } from "@/components/StatusBadge";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { format } from "date-fns";

interface Expense {
  id: string;
  title: string;
  destination: string;
  trip_start: string;
  trip_end: string;
  status: string;
  total_amount: number;
  created_at: string;
}

export default function Expenses() {
  const { user } = useAuth();
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    if (user) {
      fetchExpenses();
    }
  }, [user]);

  const fetchExpenses = async () => {
    try {
      const { data, error } = await supabase
        .from("expenses")
        .select("*")
        .eq("user_id", user?.id)
        .order("created_at", { ascending: false });

      if (error) throw error;
      setExpenses(data || []);
    } catch (error) {
      console.error("Error fetching expenses:", error);
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-8">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">My Expenses</h1>
          <p className="text-muted-foreground">
            Manage and track your expense submissions
          </p>
        </div>
        <Button onClick={() => navigate("/expenses/new")}>
          <Plus className="mr-2 h-4 w-4" />
          New Expense
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>All Expenses</CardTitle>
          <CardDescription>View and manage your expense claims</CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <p className="text-muted-foreground">Loading...</p>
          ) : expenses.length === 0 ? (
            <p className="text-muted-foreground">
              No expenses yet. Create your first expense claim to get started.
            </p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Title</TableHead>
                  <TableHead>Destination</TableHead>
                  <TableHead>Travel Dates</TableHead>
                  <TableHead>Amount</TableHead>
                  <TableHead>Status</TableHead>
                  <TableHead>Created</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {expenses.map((expense) => (
                  <TableRow key={expense.id}>
                    <TableCell className="font-medium">{expense.title}</TableCell>
                    <TableCell>{expense.destination}</TableCell>
                    <TableCell>
                      {format(new Date(expense.trip_start), "MMM d")} -{" "}
                      {format(new Date(expense.trip_end), "MMM d, yyyy")}
                    </TableCell>
                    <TableCell>${Number(expense.total_amount).toFixed(2)}</TableCell>
                    <TableCell>
                      <StatusBadge status={expense.status as any} />
                    </TableCell>
                    <TableCell>
                      {format(new Date(expense.created_at), "MMM d, yyyy")}
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => navigate(`/expenses/${expense.id}`)}
                      >
                        View
                      </Button>
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
