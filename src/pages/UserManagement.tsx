import { useEffect, useState } from "react";
import { createClient } from "@supabase/supabase-js";
import type { Database } from "@/integrations/supabase/types";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { UserPlus, Mail, User, Shield, Settings, Sparkles, CheckCircle, AlertCircle } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { z } from "zod";

const createUserSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters"),
  email: z.string().email("Invalid email address"),
  role: z.enum(["admin", "engineer", "employee", "cashier"]),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

interface CreateUserForm {
  name: string;
  email: string;
  role: "admin" | "engineer" | "employee" | "cashier";
  password: string;
  reportingEngineerId?: string | "none";
}

export default function UserManagement() {
  const { userRole } = useAuth();
  const { toast } = useToast();
  
  const [loading, setLoading] = useState(false);
  const [engineers, setEngineers] = useState<{ id: string; name: string; email: string }[]>([]);
  const [formData, setFormData] = useState<CreateUserForm>({
    name: "",
    email: "",
    role: "employee",
    password: "",
    reportingEngineerId: "none",
  });

  useEffect(() => {
    // Load engineers for assignment dropdown
    const loadEngineers = async () => {
      try {
        // 1) Get user ids with engineer role
        const { data: roleRows, error: rolesError } = await supabase
          .from("user_roles")
          .select("user_id, role")
          .eq("role", "engineer");

        if (rolesError) throw rolesError;

        const engineerIds = (roleRows || []).map(r => r.user_id);
        if (engineerIds.length === 0) {
          setEngineers([]);
          return;
        }

        // 2) Get profiles for those engineers
        const { data: profileRows, error: profilesError } = await supabase
          .from("profiles")
          .select("user_id, name, email")
          .in("user_id", engineerIds);

        if (profilesError) throw profilesError;

        const list = (profileRows || []).map(p => ({ id: p.user_id, name: p.name, email: p.email }));
        setEngineers(list);
      } catch (e) {
        console.error("Error loading engineers:", e);
      }
    };

    loadEngineers();
  }, []);

  const handleCreateUser = async (e: React.FormEvent) => {
    e.preventDefault();
    
    if (userRole !== "admin") {
      toast({
        variant: "destructive",
        title: "Access Denied",
        description: "Only administrators can create user accounts",
      });
      return;
    }

    // Check if password is empty or too short
    if (!formData.password || formData.password.length < 8) {
      toast({
        variant: "destructive",
        title: "Password Required",
        description: "Please enter a password with at least 8 characters or use the Generate button",
      });
      return;
    }

    try {
      const validated = createUserSchema.parse(formData);
      setLoading(true);

      // Create a temporary client with no session persistence so admin session isn't replaced
      const tempSupabase = createClient<Database>(
        import.meta.env.VITE_SUPABASE_URL,
        import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY,
        {
          auth: {
            persistSession: false,
            autoRefreshToken: false,
            storage: undefined,
          },
        }
      );

      // Create user using signup (this will send confirmation email)
      const { data: authData, error: authError } = await tempSupabase.auth.signUp({
        email: validated.email,
        password: validated.password,
        options: {
          data: {
            name: validated.name,
          },
        },
      });

      if (authError) {
        // Handle specific error cases
        if (authError.message.includes("already registered")) {
          throw new Error("An account with this email already exists");
        }
        throw authError;
      }

      if (!authData.user) {
        throw new Error("Failed to create user");
      }

      // Assign role to the user
      const { error: roleError } = await supabase
        .from("user_roles")
        .insert({
          user_id: authData.user.id,
          role: validated.role,
        });

      if (roleError) throw roleError;

      // If creating an employee and an engineer is chosen, link them
      if (validated.role === "employee" && formData.reportingEngineerId && formData.reportingEngineerId !== "none") {
        const { error: profileUpdateError } = await supabase
          .from("profiles")
          .update({ reporting_engineer_id: formData.reportingEngineerId })
          .eq("user_id", authData.user.id);

        if (profileUpdateError) throw profileUpdateError;
      }

      toast({
        title: "User Created Successfully",
        description: `${validated.name} has been created as ${validated.role}. They will receive an email to confirm their account.`,
      });

      // Reset form
      setFormData({
        name: "",
        email: "",
        role: "employee",
        password: "",
        reportingEngineerId: "none",
      });

    } catch (error: any) {
      console.error("Error creating user:", error);
      
      if (error instanceof z.ZodError) {
        toast({
          variant: "destructive",
          title: "Validation Error",
          description: error.errors[0].message,
        });
      } else if (error.message?.includes("already registered")) {
        toast({
          variant: "destructive",
          title: "User Already Exists",
          description: "An account with this email already exists",
        });
      } else {
        toast({
          variant: "destructive",
          title: "Error Creating User",
          description: error.message || "Failed to create user account",
        });
      }
    } finally {
      setLoading(false);
    }
  };

  const generatePassword = () => {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*";
    let password = "";
    for (let i = 0; i < 12; i++) {
      password += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    setFormData(prev => ({ ...prev, password }));
  };

  if (userRole !== "admin") {
    return (
      <div className="min-h-screen bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100 flex items-center justify-center p-4">
        <Card className="w-full max-w-md shadow-2xl border-0 bg-white/80 backdrop-blur-sm">
          <CardContent className="p-8 text-center">
            <div className="w-16 h-16 bg-red-100 rounded-full flex items-center justify-center mx-auto mb-4">
              <AlertCircle className="h-8 w-8 text-red-600" />
            </div>
            <h1 className="text-2xl font-bold text-gray-900 mb-2">Access Denied</h1>
            <p className="text-gray-600">Only administrators can access user management.</p>
          </CardContent>
        </Card>
      </div>
    );
  }

  return (
    <div className="space-y-4 sm:space-y-6 lg:space-y-8">
      {/* Mobile-optimized Header Section */}
      <div className="text-center space-y-3 sm:space-y-4">
        <div className="inline-flex items-center justify-center w-12 h-12 sm:w-16 sm:h-16 bg-gradient-to-r from-blue-600 to-indigo-600 rounded-xl sm:rounded-2xl shadow-lg">
          <UserPlus className="h-6 w-6 sm:h-8 sm:w-8 text-white" />
        </div>
        <h1 className="text-2xl sm:text-3xl lg:text-4xl font-bold bg-gradient-to-r from-gray-900 to-gray-700 bg-clip-text text-transparent">
          User Management
        </h1>
        <p className="text-sm sm:text-base lg:text-lg text-gray-600 max-w-2xl mx-auto px-4">
          Create and manage user accounts for your organization with role-based access control
        </p>
      </div>

      {/* Create User Card */}
        <Card className="shadow-2xl border-0 bg-white/80 backdrop-blur-sm overflow-hidden">
          <CardHeader className="bg-gradient-to-r from-blue-600 to-indigo-600 text-white p-8">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-white/20 rounded-lg flex items-center justify-center">
                <Sparkles className="h-5 w-5" />
              </div>
              <div>
                <CardTitle className="text-2xl font-bold">Create New User</CardTitle>
                <CardDescription className="text-blue-100 mt-1">
                  Add new team members with appropriate access levels
                </CardDescription>
              </div>
            </div>
          </CardHeader>
          <CardContent className="p-8">
            <form onSubmit={handleCreateUser} className="space-y-8">
              {/* Personal Information */}
              <div className="space-y-6">
                <div className="flex items-center gap-2 mb-4">
                  <User className="h-5 w-5 text-blue-600" />
                  <h3 className="text-lg font-semibold text-gray-900">Personal Information</h3>
                </div>
                
                <div className="grid gap-6 md:grid-cols-2">
                  <div className="space-y-3">
                    <Label htmlFor="name" className="text-sm font-medium text-gray-700">Full Name *</Label>
                    <div className="relative group">
                      <User className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400 group-focus-within:text-blue-600 transition-colors" />
                      <Input
                        id="name"
                        value={formData.name}
                        onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                        placeholder="John Doe"
                        className="pl-10 h-12 border-gray-200 focus:border-blue-500 focus:ring-blue-500/20 transition-all duration-200"
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-3">
                    <Label htmlFor="email" className="text-sm font-medium text-gray-700">Email Address *</Label>
                    <div className="relative group">
                      <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400 group-focus-within:text-blue-600 transition-colors" />
                      <Input
                        id="email"
                        type="email"
                        value={formData.email}
                        onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
                        placeholder="john.doe@company.com"
                        className="pl-10 h-12 border-gray-200 focus:border-blue-500 focus:ring-blue-500/20 transition-all duration-200"
                        required
                      />
                    </div>
                  </div>
                </div>
              </div>

              {/* Role and Security */}
              <div className="space-y-6">
                <div className="flex items-center gap-2 mb-4">
                  <Shield className="h-5 w-5 text-blue-600" />
                  <h3 className="text-lg font-semibold text-gray-900">Role & Security</h3>
                </div>
                
                <div className="grid gap-6 md:grid-cols-2">
                  <div className="space-y-3">
                    <Label htmlFor="role" className="text-sm font-medium text-gray-700">Role *</Label>
                    <div className="relative group">
                      <Settings className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400 group-focus-within:text-blue-600 transition-colors z-10" />
                      <Select
                        value={formData.role}
                        onValueChange={(value: "admin" | "engineer" | "employee" | "cashier") => 
                          setFormData(prev => ({ ...prev, role: value }))
                        }
                      >
                        <SelectTrigger className="pl-10 h-12 border-gray-200 focus:border-blue-500 focus:ring-blue-500/20 transition-all duration-200">
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent className="border-0 shadow-xl">
                          <SelectItem value="employee">
                            <div className="flex items-center gap-3 py-2">
                              <div className="w-8 h-8 bg-green-100 rounded-lg flex items-center justify-center">
                                <User className="h-4 w-4 text-green-600" />
                              </div>
                              <div>
                                <div className="font-medium">Employee</div>
                                <div className="text-xs text-gray-500">Create and submit expenses</div>
                              </div>
                            </div>
                          </SelectItem>
                          <SelectItem value="engineer">
                            <div className="flex items-center gap-3 py-2">
                              <div className="w-8 h-8 bg-blue-100 rounded-lg flex items-center justify-center">
                                <Settings className="h-4 w-4 text-blue-600" />
                              </div>
                              <div>
                                <div className="font-medium">Engineer</div>
                                <div className="text-xs text-gray-500">Review and verify expenses</div>
                              </div>
                            </div>
                          </SelectItem>
                          <SelectItem value="admin">
                            <div className="flex items-center gap-3 py-2">
                              <div className="w-8 h-8 bg-purple-100 rounded-lg flex items-center justify-center">
                                <Shield className="h-4 w-4 text-purple-600" />
                              </div>
                              <div>
                                <div className="font-medium">Administrator</div>
                                <div className="text-xs text-gray-500">Full system access</div>
                              </div>
                            </div>
                          </SelectItem>
                          <SelectItem value="cashier">
                            <div className="flex items-center gap-3 py-2">
                              <div className="w-8 h-8 bg-amber-100 rounded-lg flex items-center justify-center">
                                <Settings className="h-4 w-4 text-amber-600" />
                              </div>
                              <div>
                                <div className="font-medium">Cashier</div>
                                <div className="text-xs text-gray-500">Mark expenses as paid and manage payouts</div>
                              </div>
                            </div>
                          </SelectItem>
                        </SelectContent>
                      </Select>
                    </div>
                  </div>

                  <div className="space-y-3">
                    <Label htmlFor="reportingEngineer" className="text-sm font-medium text-gray-700">Assign Engineer (for Employee)</Label>
                    <Select
                      value={formData.reportingEngineerId || "none"}
                      onValueChange={(value) => setFormData(prev => ({ ...prev, reportingEngineerId: value }))}
                      disabled={formData.role !== "employee"}
                    >
                      <SelectTrigger className="h-12 border-gray-200 focus:border-blue-500 focus:ring-blue-500/20 transition-all duration-200">
                        <SelectValue placeholder="Select engineer" />
                      </SelectTrigger>
                      <SelectContent className="border-0 shadow-xl">
                        <SelectItem value="none">Unassigned</SelectItem>
                        {engineers.map(e => (
                          <SelectItem key={e.id} value={e.id}>
                            {e.name} ({e.email})
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                    <p className="text-xs text-gray-500">If set, all expenses will auto-assign to this engineer.</p>
                  </div>

                  <div className="space-y-3">
                    <Label htmlFor="password" className="text-sm font-medium text-gray-700">Temporary Password *</Label>
                    <div className="flex gap-3">
                      <div className="relative flex-1 group">
                        <Input
                          id="password"
                          type="password"
                          value={formData.password}
                          onChange={(e) => setFormData(prev => ({ ...prev, password: e.target.value }))}
                          placeholder="Enter temporary password (min 8 characters)"
                          className={`h-12 border-gray-200 focus:border-blue-500 focus:ring-blue-500/20 transition-all duration-200 ${
                            formData.password && formData.password.length < 8 ? "border-red-300 focus:border-red-500" : ""
                          }`}
                          required
                        />
                        {formData.password && formData.password.length >= 8 && (
                          <CheckCircle className="absolute right-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-green-500" />
                        )}
                      </div>
                      <Button
                        type="button"
                        onClick={generatePassword}
                        className="h-12 px-6 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-medium shadow-lg hover:shadow-xl transition-all duration-200"
                      >
                        <Sparkles className="h-4 w-4 mr-2" />
                        Generate
                      </Button>
                    </div>
                    {formData.password && formData.password.length < 8 && (
                      <p className="text-xs text-red-500 flex items-center gap-1">
                        <AlertCircle className="h-3 w-3" />
                        Password must be at least 8 characters long
                      </p>
                    )}
                    <p className="text-xs text-gray-500">
                      User will receive an email to confirm their account
                    </p>
                  </div>
                </div>
              </div>

              {/* Information Cards */}
              <div className="grid gap-6 md:grid-cols-2">
                <div className="bg-gradient-to-br from-blue-50 to-indigo-50 p-6 rounded-xl border border-blue-200">
                  <h4 className="font-semibold text-blue-900 mb-3 flex items-center gap-2">
                    <Shield className="h-4 w-4" />
                    Role Permissions
                  </h4>
                  <div className="space-y-2 text-sm text-blue-800">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                      <span><strong>Employee:</strong> Create and submit expense claims</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-blue-500 rounded-full"></div>
                      <span><strong>Engineer:</strong> Review and verify assigned expenses</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-purple-500 rounded-full"></div>
                      <span><strong>Admin:</strong> Full system access and user management</span>
                    </div>
                  </div>
                </div>

                <div className="bg-gradient-to-br from-emerald-50 to-green-50 p-6 rounded-xl border border-emerald-200">
                  <h4 className="font-semibold text-emerald-900 mb-3 flex items-center gap-2">
                    <CheckCircle className="h-4 w-4" />
                    Account Creation Process
                  </h4>
                  <div className="space-y-2 text-sm text-emerald-800">
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-emerald-500 rounded-full"></div>
                      <span>Password must be at least 8 characters</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-emerald-500 rounded-full"></div>
                      <span>User receives confirmation email</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-2 h-2 bg-emerald-500 rounded-full"></div>
                      <span>Account activated after email confirmation</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* Submit Button */}
              <div className="pt-4">
                <Button 
                  type="submit" 
                  className="w-full h-14 bg-gradient-to-r from-blue-600 to-indigo-600 hover:from-blue-700 hover:to-indigo-700 text-white font-semibold text-lg shadow-xl hover:shadow-2xl transition-all duration-300 transform hover:scale-[1.02]"
                  disabled={loading}
                >
                  {loading ? (
                    <div className="flex items-center gap-2">
                      <div className="w-5 h-5 border-2 border-white/30 border-t-white rounded-full animate-spin"></div>
                      Creating User...
                    </div>
                  ) : (
                    <div className="flex items-center gap-2">
                      <UserPlus className="h-5 w-5" />
                      Create User Account
                    </div>
                  )}
                </Button>
              </div>
            </form>
          </CardContent>
        </Card>

        {/* Guidelines Card */}
        <Card className="shadow-xl border-0 bg-white/80 backdrop-blur-sm">
          <CardHeader className="bg-gradient-to-r from-gray-50 to-slate-50 p-6">
            <CardTitle className="text-xl font-bold text-gray-900 flex items-center gap-2">
              <Settings className="h-5 w-5 text-gray-600" />
              User Creation Guidelines
            </CardTitle>
          </CardHeader>
          <CardContent className="p-6 space-y-6">
            <div className="grid gap-6 md:grid-cols-2">
              <div className="space-y-4">
                <h4 className="font-semibold text-gray-900 flex items-center gap-2">
                  <Shield className="h-4 w-4 text-blue-600" />
                  Security Requirements
                </h4>
                <ul className="space-y-2 text-sm text-gray-600">
                  <li className="flex items-start gap-2">
                    <div className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-2"></div>
                    <span>Passwords must be at least 8 characters long</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <div className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-2"></div>
                    <span>Users will be required to change password on first login</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <div className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-2"></div>
                    <span>Email addresses must be unique and valid</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <div className="w-1.5 h-1.5 bg-blue-500 rounded-full mt-2"></div>
                    <span>Only administrators can create user accounts</span>
                  </li>
                </ul>
              </div>
              
              <div className="space-y-4">
                <h4 className="font-semibold text-gray-900 flex items-center gap-2">
                  <UserPlus className="h-4 w-4 text-green-600" />
                  Account Management
                </h4>
                <ul className="space-y-2 text-sm text-gray-600">
                  <li className="flex items-start gap-2">
                    <div className="w-1.5 h-1.5 bg-green-500 rounded-full mt-2"></div>
                    <span>New users receive email with login instructions</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <div className="w-1.5 h-1.5 bg-green-500 rounded-full mt-2"></div>
                    <span>User roles can be modified after account creation</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <div className="w-1.5 h-1.5 bg-green-500 rounded-full mt-2"></div>
                    <span>Accounts can be deactivated if needed</span>
                  </li>
                  <li className="flex items-start gap-2">
                    <div className="w-1.5 h-1.5 bg-green-500 rounded-full mt-2"></div>
                    <span>All user actions are logged for audit purposes</span>
                  </li>
                </ul>
              </div>
            </div>
          </CardContent>
        </Card>
    </div>
  );
}