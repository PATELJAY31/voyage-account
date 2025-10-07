import { useEffect, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Plus, DollarSign, Clock, CheckCircle, XCircle, TrendingUp, Users, Receipt } from "lucide-react";
import { formatINR } from "@/lib/format";
import { useNavigate } from "react-router-dom";

interface DashboardStats {
  totalExpenses: number;
  pendingAmount: number;
  approvedAmount: number;
  rejectedCount: number;
}

export default function Dashboard() {
  const { user, userRole } = useAuth();
  const [stats, setStats] = useState<DashboardStats>({
    totalExpenses: 0,
    pendingAmount: 0,
    approvedAmount: 0,
    rejectedCount: 0,
  });
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();

  useEffect(() => {
    if (user) {
      fetchStats();
    }
  }, [user, userRole]);

  const fetchStats = async () => {
    try {
      const { data, error } = await supabase
        .from("expenses")
        .select("*")
        .eq("user_id", user?.id);

      if (error) throw error;

      const stats: DashboardStats = {
        totalExpenses: data.length,
        pendingAmount: data
          .filter((e) => ["submitted", "under_review", "verified"].includes(e.status))
          .reduce((sum, e) => sum + Number(e.total_amount), 0),
        approvedAmount: data
          .filter((e) => ["approved", "paid"].includes(e.status))
          .reduce((sum, e) => sum + Number(e.total_amount), 0),
        rejectedCount: data.filter((e) => e.status === "rejected").length,
      };

      setStats(stats);
    } catch (error) {
      console.error("Error fetching stats:", error);
    } finally {
      setLoading(false);
    }
  };

  const statCards = [
    {
      title: "Total Expenses",
      value: stats.totalExpenses,
      icon: DollarSign,
      description: "All time expenses",
    },
    {
      title: "Pending Amount",
      value: formatINR(stats.pendingAmount),
      icon: Clock,
      description: "Awaiting approval",
    },
    {
      title: "Approved Amount",
      value: formatINR(stats.approvedAmount),
      icon: CheckCircle,
      description: "Approved expenses",
    },
    {
      title: "Rejected",
      value: stats.rejectedCount,
      icon: XCircle,
      description: "Rejected expenses",
    },
  ];

  return (
    <div className="space-y-4 sm:space-y-6 lg:space-y-8">
      {/* Mobile-optimized Header */}
      <div className="flex flex-col sm:flex-row sm:justify-between sm:items-center gap-4">
        <div className="min-w-0">
          <h1 className="text-2xl sm:text-3xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-sm sm:text-base text-muted-foreground">
            Welcome back! Here's an overview of your expenses.
          </p>
        </div>
        {(userRole === "employee" || userRole === "admin") && (
          <Button 
            onClick={() => navigate("/expenses/new")}
            className="w-full sm:w-auto"
          >
            <Plus className="mr-2 h-4 w-4" />
            New Expense
          </Button>
        )}
      </div>

      {/* Mobile-optimized Stats Grid */}
      <div className="grid gap-3 sm:gap-4 grid-cols-1 sm:grid-cols-2 lg:grid-cols-4">
        {statCards.map((card) => {
          const Icon = card.icon;
          return (
            <Card key={card.title} className="hover:shadow-md transition-shadow">
              <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2 px-4 sm:px-6 pt-4 sm:pt-6">
                <CardTitle className="text-xs sm:text-sm font-medium truncate">{card.title}</CardTitle>
                <Icon className="h-4 w-4 text-muted-foreground flex-shrink-0" />
              </CardHeader>
              <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
                <div className="text-xl sm:text-2xl font-bold">{card.value}</div>
                <p className="text-xs text-muted-foreground mt-1">{card.description}</p>
              </CardContent>
            </Card>
          );
        })}
      </div>

      {/* Mobile-optimized Recent Activity */}
      <Card>
        <CardHeader className="px-4 sm:px-6 pt-4 sm:pt-6">
          <CardTitle className="text-lg sm:text-xl">Recent Activity</CardTitle>
          <CardDescription className="text-sm">Your latest expense submissions</CardDescription>
        </CardHeader>
        <CardContent className="px-4 sm:px-6 pb-4 sm:pb-6">
          <p className="text-sm text-muted-foreground">
            View your recent expenses in the{" "}
            <Button
              variant="link"
              className="p-0 h-auto text-sm"
              onClick={() => navigate("/expenses")}
            >
              My Expenses
            </Button>{" "}
            section.
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
