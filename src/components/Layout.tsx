import { SidebarProvider, SidebarTrigger } from "@/components/ui/sidebar";
import { AppSidebar } from "./AppSidebar";

export function Layout({ children }: { children: React.ReactNode }) {
  return (
    <SidebarProvider>
      <div className="min-h-screen flex w-full bg-gradient-to-br from-slate-50 via-blue-50 to-indigo-100">
        <AppSidebar />
        <main className="flex-1 flex flex-col min-w-0">
          {/* Mobile-optimized Header */}
          <header className="border-b bg-white/80 backdrop-blur-md supports-[backdrop-filter]:bg-white/60 shadow-sm sticky top-0 z-40">
            <div className="flex h-14 sm:h-16 items-center gap-2 sm:gap-4 px-3 sm:px-6">
              <SidebarTrigger className="hover:bg-gray-100 rounded-lg p-2 transition-colors flex-shrink-0" />
              <div className="flex-1 min-w-0">
                <h1 className="text-sm sm:text-base font-semibold text-gray-900 truncate">
                  Expense Management
                </h1>
                <p className="text-xs text-gray-500 hidden sm:block">
                  Travel Expense Management System
                </p>
              </div>
            </div>
          </header>
          
          {/* Mobile-optimized Content */}
          <div className="flex-1 p-3 sm:p-4 md:p-6">
            <div className="max-w-7xl mx-auto">
              {children}
            </div>
          </div>
        </main>
      </div>
    </SidebarProvider>
  );
}
