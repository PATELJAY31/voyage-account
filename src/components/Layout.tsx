import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "./AppSidebar";

export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <SidebarProvider>
      <div className="min-h-screen flex w-full bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100">
        <AppSidebar />
        <main className="flex-1 flex flex-col">
          <header className="border-b bg-white/80 backdrop-blur-md supports-[backdrop-filter]:bg-white/60 shadow-sm">
            <div className="flex h-16 items-center gap-4 px-6">
              <SidebarTrigger className="hover:bg-gray-100 rounded-lg p-2 transition-colors" />
              <div className="flex-1" />
              <div className="text-sm text-gray-600">
                Travel Expense Management System
              </div>
            </div>
          </header>
          <div className="flex-1 p-6">
            <div className="max-w-7xl mx-auto">
              {children}
            </div>
          </div>
        </main>
      </div>
    </SidebarProvider>
  );
}
