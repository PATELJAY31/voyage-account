import { Toaster } from "@/components/ui/toaster";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { TooltipProvider } from "@/components/ui/tooltip";
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Routes, Route, Navigate } from "react-router-dom";
import { AuthProvider } from "@/contexts/AuthContext";
import { ProtectedRoute } from "@/components/ProtectedRoute";
import { Layout } from "@/components/Layout";
import Auth from "./pages/Auth";
import Dashboard from "./pages/Dashboard";
import Expenses from "./pages/Expenses";
import ExpenseForm from "./pages/ExpenseForm";
import ExpenseDetail from "./pages/ExpenseDetail";
import AdminPanel from "./pages/AdminPanel";
import EngineerReview from "./pages/EngineerReview";
import Analytics from "./pages/Analytics";
import ExpenseTemplates from "./pages/ExpenseTemplates";
import Notifications from "./pages/Notifications";
import UserManagement from "./pages/UserManagement";
import NotFound from "./pages/NotFound";

const queryClient = new QueryClient();

const App = () => (
  <QueryClientProvider client={queryClient}>
    <TooltipProvider>
      <Toaster />
      <Sonner />
      <BrowserRouter>
        <AuthProvider>
          <Routes>
            <Route path="/" element={<Navigate to="/dashboard" replace />} />
            <Route path="/auth" element={<Auth />} />
            <Route
              path="/dashboard"
              element={
                <ProtectedRoute>
                  <Layout>
                    <Dashboard />
                  </Layout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/expenses"
              element={
                <ProtectedRoute allowedRoles={["employee", "admin"]}>
                  <Layout>
                    <Expenses />
                  </Layout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/expenses/new"
              element={
                <ProtectedRoute allowedRoles={["employee", "admin"]}>
                  <Layout>
                    <ExpenseForm />
                  </Layout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/expenses/:id"
              element={
                <ProtectedRoute allowedRoles={["employee", "admin", "engineer"]}>
                  <Layout>
                    <ExpenseDetail />
                  </Layout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/expenses/:id/edit"
              element={
                <ProtectedRoute allowedRoles={["employee", "admin"]}>
                  <Layout>
                    <ExpenseForm />
                  </Layout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/expenses"
              element={
                <ProtectedRoute allowedRoles={["admin"]}>
                  <Layout>
                    <AdminPanel />
                  </Layout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/admin/users"
              element={
                <ProtectedRoute allowedRoles={["admin"]}>
                  <Layout>
                    <UserManagement />
                  </Layout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/review"
              element={
                <ProtectedRoute allowedRoles={["engineer"]}>
                  <Layout>
                    <EngineerReview />
                  </Layout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/analytics"
              element={
                <ProtectedRoute allowedRoles={["employee", "admin"]}>
                  <Layout>
                    <Analytics />
                  </Layout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/templates"
              element={
                <ProtectedRoute allowedRoles={["employee", "admin"]}>
                  <Layout>
                    <ExpenseTemplates />
                  </Layout>
                </ProtectedRoute>
              }
            />
            <Route
              path="/notifications"
              element={
                <ProtectedRoute allowedRoles={["employee", "admin", "engineer"]}>
                  <Layout>
                    <Notifications />
                  </Layout>
                </ProtectedRoute>
              }
            />
            {/* ADD ALL CUSTOM ROUTES ABOVE THE CATCH-ALL "*" ROUTE */}
            <Route path="*" element={<NotFound />} />
          </Routes>
        </AuthProvider>
      </BrowserRouter>
    </TooltipProvider>
  </QueryClientProvider>
);

export default App;
