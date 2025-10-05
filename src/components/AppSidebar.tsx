import { NavLink } from "react-router-dom";
import {
  LayoutDashboard,
  Receipt,
  Users,
  FileText,
  LogOut,
} from "lucide-react";
import {
  Sidebar,
  SidebarContent,
  SidebarGroup,
  SidebarGroupContent,
  SidebarGroupLabel,
  SidebarMenu,
  SidebarMenuButton,
  SidebarMenuItem,
  SidebarFooter,
} from "@/components/ui/sidebar";
import { useAuth } from "@/contexts/AuthContext";
import { Button } from "@/components/ui/button";

export function AppSidebar() {
  const { userRole, signOut } = useAuth();

  const employeeItems = [
    { title: "Dashboard", url: "/dashboard", icon: LayoutDashboard },
    { title: "My Expenses", url: "/expenses", icon: Receipt },
  ];

  const engineerItems = [
    { title: "Dashboard", url: "/dashboard", icon: LayoutDashboard },
    { title: "Review Expenses", url: "/review", icon: FileText },
  ];

  const adminItems = [
    { title: "Dashboard", url: "/dashboard", icon: LayoutDashboard },
    { title: "All Expenses", url: "/admin/expenses", icon: Receipt },
    { title: "Manage Users", url: "/admin/users", icon: Users },
  ];

  const items = 
    userRole === "admin" ? adminItems :
    userRole === "engineer" ? engineerItems :
    employeeItems;

  return (
    <Sidebar>
      <SidebarContent>
        <div className="px-6 py-4">
          <div className="flex items-center gap-2">
            <Receipt className="h-6 w-6 text-primary" />
            <span className="font-bold text-lg">ExpenseTracker</span>
          </div>
        </div>

        <SidebarGroup>
          <SidebarGroupLabel>Navigation</SidebarGroupLabel>
          <SidebarGroupContent>
            <SidebarMenu>
              {items.map((item) => (
                <SidebarMenuItem key={item.title}>
                  <SidebarMenuButton asChild>
                    <NavLink 
                      to={item.url}
                      className={({ isActive }) =>
                        isActive ? "bg-sidebar-accent text-sidebar-accent-foreground" : ""
                      }
                    >
                      <item.icon className="h-4 w-4" />
                      <span>{item.title}</span>
                    </NavLink>
                  </SidebarMenuButton>
                </SidebarMenuItem>
              ))}
            </SidebarMenu>
          </SidebarGroupContent>
        </SidebarGroup>
      </SidebarContent>

      <SidebarFooter>
        <Button
          variant="ghost"
          className="w-full justify-start"
          onClick={() => signOut()}
        >
          <LogOut className="mr-2 h-4 w-4" />
          Sign Out
        </Button>
      </SidebarFooter>
    </Sidebar>
  );
}
