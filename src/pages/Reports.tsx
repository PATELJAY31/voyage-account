import { useEffect, useMemo, useState } from "react";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useAuth } from "@/contexts/AuthContext";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

interface UserRow {
  user_id: string;
  name: string;
  email: string;
  balance: number;
  role: string;
}

interface ExpenseRow {
  id: string;
  user_id: string;
  title: string | null;
  total_amount: number | null;
  status: string | null;
  created_at: string;
  updated_at: string | null;
}

export default function Reports() {
  const { userRole } = useAuth();
  const [fromDate, setFromDate] = useState<string>("");
  const [toDate, setToDate] = useState<string>("");
  const [minBalance, setMinBalance] = useState<string>("");
  const [maxBalance, setMaxBalance] = useState<string>("");
  const [loading, setLoading] = useState(false);
  const [users, setUsers] = useState<UserRow[]>([]);
  const [expenses, setExpenses] = useState<ExpenseRow[]>([]);
  const [selectedUserId, setSelectedUserId] = useState<string>("all");
  const [categories, setCategories] = useState<string[]>([]);
  const [selectedCategory, setSelectedCategory] = useState<string>("all");

  const balanceMinNum = useMemo(() => (minBalance === "" ? undefined : Number(minBalance)), [minBalance]);
  const balanceMaxNum = useMemo(() => (maxBalance === "" ? undefined : Number(maxBalance)), [maxBalance]);

  useEffect(() => {
    if (userRole === "admin") {
      void fetchUsers();
      void fetchExpenses();
      void fetchCategories();
    }
  }, [userRole]);

  const fetchUsers = async () => {
    try {
      setLoading(true);
      const { data: profiles, error: profilesError } = await supabase
        .from("profiles")
        .select("user_id, name, email, balance");
      if (profilesError) throw profilesError;
      const ids = (profiles || []).map(p => p.user_id);
      let rolesById: Record<string, string> = {};
      if (ids.length > 0) {
        const { data: rolesRows, error: rolesErr } = await supabase
          .from("user_roles")
          .select("user_id, role")
          .in("user_id", ids);
        if (rolesErr) throw rolesErr;
        (rolesRows || []).forEach(r => { rolesById[r.user_id] = r.role; });
      }
      const combined: UserRow[] = (profiles || []).map((p: any) => ({
        user_id: p.user_id,
        name: p.name || "",
        email: p.email || "",
        balance: Number(p.balance ?? 0),
        role: rolesById[p.user_id] || "employee",
      }));
      setUsers(combined);
    } catch (e) {
      console.error("Failed to fetch users for reports", e);
    } finally {
      setLoading(false);
    }
  };

  const fetchExpenses = async () => {
    try {
      setLoading(true);
      // First try with category (if exists)
      let query = supabase
        .from("expenses")
        .select("id, user_id, title, total_amount, status, created_at, updated_at, category");
      if (fromDate) query = query.gte("created_at", new Date(fromDate).toISOString());
      if (toDate) {
        const end = new Date(toDate); end.setHours(23,59,59,999); query = query.lte("created_at", end.toISOString());
      }
      if (selectedUserId !== "all") query = query.eq("user_id", selectedUserId);
      if (selectedCategory !== "all") query = query.eq("category", selectedCategory);
      let { data, error } = await query.order("created_at", { ascending: false });
      if (error && (error as any).code === '42703') {
        // Retry without category column/filter
        let q2 = supabase
          .from("expenses")
          .select("id, user_id, title, total_amount, status, created_at, updated_at");
        if (fromDate) q2 = q2.gte("created_at", new Date(fromDate).toISOString());
        if (toDate) { const end = new Date(toDate); end.setHours(23,59,59,999); q2 = q2.lte("created_at", end.toISOString()); }
        if (selectedUserId !== "all") q2 = q2.eq("user_id", selectedUserId);
        const res2 = await q2.order("created_at", { ascending: false });
        data = res2.data as any;
        error = res2.error as any;
      }
      if (error) throw error;
      setExpenses((data as ExpenseRow[]) || []);
    } catch (e) {
      console.error("Failed to fetch expenses for reports", e);
    } finally {
      setLoading(false);
    }
  };

  const fetchCategories = async () => {
    try {
      // Try with is_active first
      let { data, error } = await supabase
        .from("expense_categories")
        .select("name")
        .eq("is_active", true)
        .order("name", { ascending: true });
      if (error && (error as any).code === '42703') {
        // Retry with active, then without filter
        let r2 = await supabase
          .from("expense_categories")
          .select("name")
          .eq("active", true)
          .order("name", { ascending: true });
        data = r2.data as any;
        error = r2.error as any;
        if (error && (error as any).code === '42703') {
          const r3 = await supabase
            .from("expense_categories")
            .select("name")
            .order("name", { ascending: true });
          data = r3.data as any;
          error = r3.error as any;
        }
      }
      if (error) throw error;
      setCategories((data || []).map((r: any) => r.name));
    } catch (e) {
      console.warn("Categories not available or failed to load; category filter will be limited.", e);
      setCategories([]);
    }
  };

  const filteredUsers = useMemo(() => {
    return users.filter(u => {
      if (selectedUserId !== "all" && u.user_id !== selectedUserId) return false;
      if (typeof balanceMinNum === "number" && u.balance < balanceMinNum) return false;
      if (typeof balanceMaxNum === "number" && u.balance > balanceMaxNum) return false;
      return true;
    });
  }, [users, balanceMinNum, balanceMaxNum, selectedUserId]);

  const usersById = useMemo(() => new Map(filteredUsers.map(u => [u.user_id, u])), [filteredUsers]);

  const usersCsv = () => {
    const rows = filteredUsers.map(u => ({
      user_id: u.user_id,
      name: u.name,
      email: u.email,
      role: u.role,
      balance: u.balance,
    }));
    const totalBalance = rows.reduce((sum, r) => sum + Number(r.balance || 0), 0);
    const totalsRow: Record<string, any> = rows.length > 0 ? {
      user_id: "",
      name: "",
      email: "",
      role: "TOTAL",
      balance: totalBalance,
    } : {};
    downloadCsv("users.csv", rows, totalsRow);
  };

  const expensesCsv = () => {
    const rows = expenses.map(e => {
      const u = usersById.get(e.user_id);
      return {
        expense_id: e.id,
        user_id: e.user_id,
        name: u?.name || "",
        email: u?.email || "",
        title: e.title || "",
        amount: Number(e.total_amount ?? 0),
        status: e.status || "",
        category: (e as any).category || "",
        created_at: e.created_at,
        updated_at: e.updated_at || "",
      };
    });
    const totalAmount = rows.reduce((sum, r) => sum + Number(r.amount || 0), 0);
    const totalsRow: Record<string, any> = rows.length > 0 ? {
      expense_id: "",
      user_id: "",
      name: "",
      email: "",
      title: "TOTAL",
      amount: totalAmount,
      status: "",
      category: rows[0].hasOwnProperty("category") ? "" : undefined,
      created_at: "",
      updated_at: "",
    } : {};
    downloadCsv("expenses.csv", rows, totalsRow);
  };

  const usersAndExpensesCsv = () => {
    // Apply both filters: user balance range and expense date range already applied
    const rows = expenses
      .filter(e => usersById.has(e.user_id))
      .map(e => {
        const u = usersById.get(e.user_id)!;
        return {
          user_id: u.user_id,
          name: u.name,
          email: u.email,
          role: u.role,
          balance: u.balance,
          expense_id: e.id,
          title: e.title || "",
          amount: Number(e.total_amount ?? 0),
          status: e.status || "",
          category: (e as any).category || "",
          created_at: e.created_at,
          updated_at: e.updated_at || "",
        };
      });
    const totalBalance = rows.reduce((sum, r) => sum + Number(r.balance || 0), 0);
    const totalAmount = rows.reduce((sum, r) => sum + Number(r.amount || 0), 0);
    const totalsRow: Record<string, any> = rows.length > 0 ? {
      user_id: "",
      name: "",
      email: "",
      role: "TOTAL",
      balance: totalBalance,
      expense_id: "",
      title: "",
      amount: totalAmount,
      status: "",
      category: rows[0].hasOwnProperty("category") ? "" : undefined,
      created_at: "",
      updated_at: "",
    } : {};
    downloadCsv("users_expenses.csv", rows, totalsRow);
  };

  const downloadCsv = (filename: string, data: Record<string, any>[], totalsRow?: Record<string, any>) => {
    if (!data || data.length === 0) {
      // create empty with message
      const blob = new Blob(["No data"], { type: "text/csv;charset=utf-8;" });
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      a.click();
      URL.revokeObjectURL(url);
      return;
    }
    const headers = Object.keys(data[0]);
    const lines: string[] = [];
    lines.push(headers.join(","));
    for (const row of data) {
      lines.push(headers.map(h => escapeCsv(String(row[h] ?? ""))).join(","));
    }
    if (totalsRow && Object.keys(totalsRow).length > 0) {
      // Ensure totals row aligns to headers; fill missing keys
      const normalized: Record<string, any> = {};
      headers.forEach(h => { normalized[h] = totalsRow[h] ?? ""; });
      lines.push(headers.map(h => escapeCsv(String(normalized[h]))).join(","));
    }
    const csv = lines.join("\n");
    const blob = new Blob([csv], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = filename;
    a.click();
    URL.revokeObjectURL(url);
  };

  const escapeCsv = (value: string) => {
    if (value.includes(",") || value.includes("\n") || value.includes('"')) {
      return '"' + value.replace(/"/g, '""') + '"';
    }
    return value;
  };

  return (
    <div className="space-y-6">
      <div className="text-center space-y-2">
        <h1 className="text-2xl font-bold">Reports</h1>
        <p className="text-sm text-slate-600">Export Users, Expenses, or Users+Expenses with filters</p>
      </div>

      <Card className="shadow-md border-0">
        <CardHeader>
          <CardTitle>Filters</CardTitle>
          <CardDescription>Date range applies to expenses; balance range applies to users</CardDescription>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label>From date</Label>
              <Input type="date" value={fromDate} onChange={(e) => setFromDate(e.target.value)} />
            </div>
            <div className="space-y-2">
              <Label>To date</Label>
              <Input type="date" value={toDate} onChange={(e) => setToDate(e.target.value)} />
            </div>
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label>Min balance</Label>
              <Input type="number" inputMode="decimal" value={minBalance} onChange={(e) => setMinBalance(e.target.value)} placeholder="e.g. 0" />
            </div>
            <div className="space-y-2">
              <Label>Max balance</Label>
              <Input type="number" inputMode="decimal" value={maxBalance} onChange={(e) => setMaxBalance(e.target.value)} placeholder="e.g. 10000" />
            </div>
          </div>
          <div className="grid gap-4 md:grid-cols-2">
            <div className="space-y-2">
              <Label>User</Label>
              <Select value={selectedUserId} onValueChange={setSelectedUserId}>
                <SelectTrigger>
                  <SelectValue placeholder="All users" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All users</SelectItem>
                  {users.map(u => (
                    <SelectItem key={u.user_id} value={u.user_id}>{u.name || u.email}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Category</Label>
              <Select value={selectedCategory} onValueChange={setSelectedCategory}>
                <SelectTrigger>
                  <SelectValue placeholder="All categories" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">All categories</SelectItem>
                  {categories.map((c) => (
                    <SelectItem key={c} value={c}>{c}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          </div>
          <div className="flex gap-3 pt-2">
            <Button variant="outline" onClick={() => { setFromDate(""); setToDate(""); setMinBalance(""); setMaxBalance(""); setSelectedUserId("all"); setSelectedCategory("all"); }}>Clear</Button>
            <Button onClick={() => { void fetchUsers(); void fetchExpenses(); }} disabled={loading}>Apply</Button>
          </div>
        </CardContent>
      </Card>

      <Card className="shadow-md border-0">
        <CardHeader>
          <CardTitle>Export</CardTitle>
          <CardDescription>Download CSV files</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-3">
          <Button onClick={usersCsv} disabled={loading}>Download Users CSV</Button>
          <Button onClick={expensesCsv} disabled={loading}>Download Expenses CSV</Button>
          <Button onClick={usersAndExpensesCsv} disabled={loading}>Download Users+Expenses CSV</Button>
        </CardContent>
      </Card>
    </div>
  );
}


