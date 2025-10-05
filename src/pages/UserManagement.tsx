import { useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/integrations/supabase/client";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { UserPlus, Mail, User, Shield, Settings } from "lucide-react";
import { useToast } from "@/hooks/use-toast";
import { z } from "zod";

const createUserSchema = z.object({
  name: z.string().min(2, "Name must be at least 2 characters"),
  email: z.string().email("Invalid email address"),
  role: z.enum(["admin", "engineer", "employee"]),
  password: z.string().min(8, "Password must be at least 8 characters"),
});

interface CreateUserForm {
  name: string;
  email: string;
  role: "admin" | "engineer" | "employee";
  password: string;
}

export default function UserManagement() {
  const { userRole } = useAuth();
  const { toast } = useToast();
  
  const [loading, setLoading] = useState(false);
  const [formData, setFormData] = useState<CreateUserForm>({
    name: "",
    email: "",
    role: "employee",
    password: "",
  });

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

      // Create user in Supabase Auth
      const { data: authData, error: authError } = await supabase.auth.admin.createUser({
        email: validated.email,
        password: validated.password,
        email_confirm: true, // Auto-confirm email for admin-created accounts
        user_metadata: {
          name: validated.name,
        },
      });

      if (authError) throw authError;

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

      toast({
        title: "User Created Successfully",
        description: `${validated.name} has been created as ${validated.role}`,
      });

      // Reset form
      setFormData({
        name: "",
        email: "",
        role: "employee",
        password: "",
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
      <div className="space-y-8">
        <div className="text-center">
          <h1 className="text-3xl font-bold tracking-tight">Access Denied</h1>
          <p className="text-muted-foreground">Only administrators can access user management.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">User Management</h1>
          <p className="text-muted-foreground">
            Create and manage user accounts for your organization
          </p>
        </div>
      </div>

      {/* Create User Card */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <UserPlus className="h-5 w-5" />
            Create New User
          </CardTitle>
          <CardDescription>
            Create new employee, engineer, or admin accounts. Only administrators can create user accounts.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={handleCreateUser} className="space-y-6">
            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="name">Full Name *</Label>
                <div className="relative">
                  <User className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="name"
                    value={formData.name}
                    onChange={(e) => setFormData(prev => ({ ...prev, name: e.target.value }))}
                    placeholder="John Doe"
                    className="pl-10"
                    required
                  />
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="email">Email Address *</Label>
                <div className="relative">
                  <Mail className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Input
                    id="email"
                    type="email"
                    value={formData.email}
                    onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
                    placeholder="john.doe@company.com"
                    className="pl-10"
                    required
                  />
                </div>
              </div>
            </div>

            <div className="grid gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <Label htmlFor="role">Role *</Label>
                <div className="relative">
                  <Shield className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-muted-foreground" />
                  <Select
                    value={formData.role}
                    onValueChange={(value: "admin" | "engineer" | "employee") => 
                      setFormData(prev => ({ ...prev, role: value }))
                    }
                  >
                    <SelectTrigger className="pl-10">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="employee">
                        <div className="flex items-center gap-2">
                          <User className="h-4 w-4" />
                          Employee
                        </div>
                      </SelectItem>
                      <SelectItem value="engineer">
                        <div className="flex items-center gap-2">
                          <Settings className="h-4 w-4" />
                          Engineer
                        </div>
                      </SelectItem>
                      <SelectItem value="admin">
                        <div className="flex items-center gap-2">
                          <Shield className="h-4 w-4" />
                          Administrator
                        </div>
                      </SelectItem>
                    </SelectContent>
                  </Select>
                </div>
              </div>

              <div className="space-y-2">
                <Label htmlFor="password">Temporary Password *</Label>
                <div className="flex gap-2">
                  <Input
                    id="password"
                    type="password"
                    value={formData.password}
                    onChange={(e) => setFormData(prev => ({ ...prev, password: e.target.value }))}
                    placeholder="Enter temporary password (min 8 characters)"
                    required
                    className={formData.password && formData.password.length < 8 ? "border-red-500" : ""}
                  />
                  <Button
                    type="button"
                    variant="default"
                    onClick={generatePassword}
                    className="whitespace-nowrap bg-blue-600 hover:bg-blue-700"
                  >
                    Generate Secure Password
                  </Button>
                </div>
                {formData.password && formData.password.length < 8 && (
                  <p className="text-xs text-red-500">
                    Password must be at least 8 characters long
                  </p>
                )}
                <p className="text-xs text-muted-foreground">
                  User will be required to change this password on first login
                </p>
              </div>
            </div>

            <div className="bg-muted/50 p-4 rounded-lg">
              <h4 className="font-medium mb-2">Role Permissions:</h4>
              <div className="space-y-1 text-sm text-muted-foreground">
                <div><strong>Employee:</strong> Create and submit expense claims, view own expenses</div>
                <div><strong>Engineer:</strong> Review and verify assigned expenses, add comments</div>
                <div><strong>Admin:</strong> Full system access, user management, expense approval</div>
              </div>
            </div>

            <div className="bg-blue-50 p-4 rounded-lg border border-blue-200">
              <h4 className="font-medium mb-2 text-blue-800">Password Requirements:</h4>
              <div className="space-y-1 text-sm text-blue-700">
                <div>• Minimum 8 characters long</div>
                <div>• Use the "Generate Secure Password" button for a strong password</div>
                <div>• User will be required to change password on first login</div>
              </div>
            </div>

            <Button type="submit" className="w-full" disabled={loading}>
              {loading ? "Creating User..." : "Create User Account"}
            </Button>
          </form>
        </CardContent>
      </Card>

      {/* User Creation Guidelines */}
      <Card>
        <CardHeader>
          <CardTitle>User Creation Guidelines</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="space-y-2">
            <h4 className="font-medium">Security Requirements:</h4>
            <ul className="text-sm text-muted-foreground space-y-1 ml-4">
              <li>• Passwords must be at least 8 characters long</li>
              <li>• Users will be required to change their password on first login</li>
              <li>• Email addresses must be unique and valid</li>
              <li>• Only administrators can create new user accounts</li>
            </ul>
          </div>
          
          <div className="space-y-2">
            <h4 className="font-medium">Account Management:</h4>
            <ul className="text-sm text-muted-foreground space-y-1 ml-4">
              <li>• New users will receive an email with login instructions</li>
              <li>• User roles can be modified after account creation</li>
              <li>• Accounts can be deactivated if needed</li>
              <li>• All user actions are logged for audit purposes</li>
            </ul>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
