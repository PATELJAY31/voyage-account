import { useEffect, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { Input } from "@/components/ui/input";
import { Button } from "@/components/ui/button";
import { useToast } from "@/hooks/use-toast";
import { formatINR } from "@/lib/format";

interface ProfileRow {
  user_id: string;
  name: string;
  email: string;
  balance: number | null;
}

export default function Balances() {
  const { userRole } = useAuth();
  const { toast } = useToast();
  const [loading, setLoading] = useState(true);
  const [rows, setRows] = useState<ProfileRow[]>([]);
  const [savingId, setSavingId] = useState<string | null>(null);

  const canEdit = userRole === "admin" || userRole === "cashier" || userRole === "engineer";

  useEffect(() => {
    fetchProfiles();
  }, []);

  const fetchProfiles = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from("profiles")
        .select("user_id, name, email, balance")
        .order("name", { ascending: true });
      if (error) throw error;
      setRows((data || []).map((r: any) => ({
        user_id: r.user_id,
        name: r.name,
        email: r.email,
        balance: typeof r.balance === 'number' ? r.balance : 0,
      })));
    } catch (e: any) {
      console.error("Error loading balances", e);
    } finally {
      setLoading(false);
    }
  };

  const updateBalance = async (userId: string, newBalance: number) => {
    try {
      setSavingId(userId);
      const { error } = await supabase
        .from("profiles")
        .update({ balance: newBalance })
        .eq("user_id", userId);
      if (error) throw error;
      toast({ title: "Balance updated", description: "Employee balance has been saved" });
      setRows(prev => prev.map(r => r.user_id === userId ? { ...r, balance: newBalance } : r));
    } catch (e: any) {
      toast({ variant: "destructive", title: "Error", description: e.message || "Failed to update balance" });
    } finally {
      setSavingId(null);
    }
  };

  if (!canEdit) {
    return (
      <div className="space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold tracking-tight">Access Denied</h1>
          <p className="text-muted-foreground">You don't have permission to access balances.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold tracking-tight">Employee Balances</h1>
        <p className="text-muted-foreground">View and manage initial balances for employees</p>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Balances</CardTitle>
          <CardDescription>Adjust available balance for each employee</CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <p className="text-muted-foreground">Loading...</p>
          ) : (
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>Employee</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead className="text-right">Balance</TableHead>
                  <TableHead className="text-right">Actions</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {rows.map((r) => (
                  <TableRow key={r.user_id}>
                    <TableCell className="font-medium">{r.name}</TableCell>
                    <TableCell>{r.email}</TableCell>
                    <TableCell className="text-right">
                      <div className="flex items-center justify-end gap-2">
                        <Input
                          type="number"
                          className="w-32 h-9"
                          value={String(r.balance ?? 0)}
                          onChange={(e) => {
                            const val = parseFloat(e.target.value || '0');
                            setRows(prev => prev.map(x => x.user_id === r.user_id ? { ...x, balance: isNaN(val) ? 0 : val } : x));
                          }}
                        />
                        <span className="text-xs text-muted-foreground">INR</span>
                      </div>
                    </TableCell>
                    <TableCell className="text-right">
                      <Button
                        size="sm"
                        disabled={savingId === r.user_id}
                        onClick={() => updateBalance(r.user_id, Number(r.balance ?? 0))}
                      >
                        {savingId === r.user_id ? "Saving..." : "Save"}
                      </Button>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          )}
        </CardContent>
      </Card>
      <div className="text-sm text-muted-foreground">Note: Balance is automatically reduced when an expense is approved by admin.</div>
    </div>
  );
}


