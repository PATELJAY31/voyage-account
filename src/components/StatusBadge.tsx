import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

type ExpenseStatus = "submitted" | "verified" | "approved";

interface StatusBadgeProps {
  status: ExpenseStatus | string;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const statusConfig: Record<string, { label: string; variant: "default" | "secondary" | "destructive" | "outline" | "success" }> = {
    submitted: { label: "Submitted", variant: "default" as const },
    verified: { label: "Verified", variant: "default" as const },
    approved: { label: "Approved", variant: "success" as const },
  };

  const config = statusConfig[status] || { label: String(status), variant: "secondary" as const };

  return (
    <Badge variant={config.variant} className={cn(className)}>
      {config.label}
    </Badge>
  );
}
