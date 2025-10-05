import { Badge } from "@/components/ui/badge";
import { cn } from "@/lib/utils";

type ExpenseStatus = "draft" | "submitted" | "under_review" | "verified" | "approved" | "rejected" | "paid";

interface StatusBadgeProps {
  status: ExpenseStatus;
  className?: string;
}

export function StatusBadge({ status, className }: StatusBadgeProps) {
  const statusConfig = {
    draft: { label: "Draft", variant: "secondary" as const },
    submitted: { label: "Submitted", variant: "default" as const },
    under_review: { label: "Under Review", variant: "default" as const },
    verified: { label: "Verified", variant: "default" as const },
    approved: { label: "Approved", variant: "success" as const },
    rejected: { label: "Rejected", variant: "destructive" as const },
    paid: { label: "Paid", variant: "success" as const },
  };

  const config = statusConfig[status];

  return (
    <Badge variant={config.variant} className={cn(className)}>
      {config.label}
    </Badge>
  );
}
