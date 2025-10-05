import { useState, useEffect } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { useAuth } from "@/contexts/AuthContext";
import { supabase } from "@/integrations/supabase/client";
import { useToast } from "@/hooks/use-toast";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Calendar } from "@/components/ui/calendar";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { CalendarIcon, Plus, Trash2, Save, Send } from "lucide-react";
import { format } from "date-fns";
import { cn } from "@/lib/utils";
import { FileUpload } from "@/components/FileUpload";
import { ExpenseService, CreateExpenseData, UpdateExpenseData } from "@/services/ExpenseService";
import { z } from "zod";

const expenseSchema = z.object({
  title: z.string().min(1, "Title is required"),
  destination: z.string().min(1, "Destination is required"),
  trip_start: z.date(),
  trip_end: z.date(),
  purpose: z.string().optional(),
});

const lineItemSchema = z.object({
  date: z.date(),
  category: z.enum(["travel", "lodging", "food", "other"]),
  amount: z.number().positive("Amount must be positive"),
  description: z.string().min(1, "Description is required"),
});

interface LineItem {
  id?: string;
  date: Date;
  category: "travel" | "lodging" | "food" | "other";
  amount: number;
  description: string;
}

export default function ExpenseForm() {
  const { user } = useAuth();
  const { id } = useParams();
  const navigate = useNavigate();
  const { toast } = useToast();
  
  const [loading, setLoading] = useState(false);
  const [expense, setExpense] = useState({
    title: "",
    destination: "",
    trip_start: new Date(),
    trip_end: new Date(),
    purpose: "",
  });
  const [lineItems, setLineItems] = useState<LineItem[]>([]);
  const [isEditing, setIsEditing] = useState(false);
  const [currentExpenseId, setCurrentExpenseId] = useState<string | null>(null);

  useEffect(() => {
    if (id && id !== "new") {
      fetchExpense();
      setIsEditing(true);
    } else if (id === "new") {
      // Check for template data
      const templateData = sessionStorage.getItem('expenseTemplate');
      if (templateData) {
        try {
          const template = JSON.parse(templateData);
          setExpense(prev => ({
            ...prev,
            title: template.title || "",
            purpose: template.purpose || ""
          }));
          
          if (template.commonItems) {
            setLineItems(template.commonItems.map((item: any) => ({
              date: new Date(),
              category: item.category,
              amount: item.estimatedAmount,
              description: item.description
            })));
          }
          
          // Clear template data after use
          sessionStorage.removeItem('expenseTemplate');
        } catch (error) {
          console.error("Error parsing template data:", error);
        }
      }
    }
  }, [id]);

  const fetchExpense = async () => {
    try {
      const { data: expenseData, error: expenseError } = await supabase
        .from("expenses")
        .select("*")
        .eq("id", id)
        .single();

      if (expenseError) throw expenseError;

      setExpense({
        title: expenseData.title,
        destination: expenseData.destination,
        trip_start: new Date(expenseData.trip_start),
        trip_end: new Date(expenseData.trip_end),
        purpose: expenseData.purpose || "",
      });

      setCurrentExpenseId(expenseData.id);

      const { data: lineItemsData, error: lineItemsError } = await supabase
        .from("expense_line_items")
        .select("*")
        .eq("expense_id", id)
        .order("date");

      if (lineItemsError) throw lineItemsError;

      setLineItems(
        lineItemsData.map((item) => ({
          id: item.id,
          date: new Date(item.date),
          category: item.category,
          amount: Number(item.amount),
          description: item.description,
        }))
      );
    } catch (error) {
      console.error("Error fetching expense:", error);
      toast({
        variant: "destructive",
        title: "Error",
        description: "Failed to load expense data",
      });
    }
  };

  const addLineItem = () => {
    setLineItems([
      ...lineItems,
      {
        date: new Date(),
        category: "travel",
        amount: 0,
        description: "",
      },
    ]);
  };

  const updateLineItem = (index: number, field: keyof LineItem, value: any) => {
    const updated = [...lineItems];
    updated[index] = { ...updated[index], [field]: value };
    setLineItems(updated);
  };

  const removeLineItem = (index: number) => {
    setLineItems(lineItems.filter((_, i) => i !== index));
  };

  const calculateTotal = () => {
    return lineItems.reduce((sum, item) => sum + item.amount, 0);
  };

  const saveExpense = async (status: "draft" | "submitted" = "draft") => {
    if (!user) return;

    try {
      setLoading(true);

      // Validate expense data
      const validatedExpense = expenseSchema.parse({
        ...expense,
        trip_start: expense.trip_start,
        trip_end: expense.trip_end,
      });

      // Validate line items
      const validatedLineItems = lineItems.map(item => 
        lineItemSchema.parse({
          ...item,
          date: item.date,
        })
      );

      if (validatedLineItems.length === 0) {
        throw new Error("At least one line item is required");
      }

      // Prepare data for ExpenseService
      const expenseData: CreateExpenseData | UpdateExpenseData = {
        title: validatedExpense.title,
        destination: validatedExpense.destination,
        trip_start: validatedExpense.trip_start.toISOString().split('T')[0],
        trip_end: validatedExpense.trip_end.toISOString().split('T')[0],
        purpose: validatedExpense.purpose,
        line_items: validatedLineItems.map(item => ({
          date: item.date.toISOString().split('T')[0],
          category: item.category,
          amount: item.amount,
          description: item.description,
        })),
      };

      if (isEditing && id) {
        // Update existing expense
        await ExpenseService.updateExpense(id, user.id, {
          ...expenseData,
          status: status,
        });
      } else {
        // Create new expense
        const newExpense = await ExpenseService.createExpense(user.id, expenseData as CreateExpenseData);
        setCurrentExpenseId(newExpense.id);
        
        // If submitting, update status
        if (status === "submitted") {
          await ExpenseService.submitExpense(newExpense.id, user.id);
        }
      }

      toast({
        title: "Success",
        description: `Expense ${status === "draft" ? "saved as draft" : "submitted"} successfully`,
      });

      navigate("/expenses");
    } catch (error: any) {
      console.error("Error saving expense:", error);
      if (error instanceof z.ZodError) {
        toast({
          variant: "destructive",
          title: "Validation Error",
          description: error.errors[0].message,
        });
      } else {
        toast({
          variant: "destructive",
          title: "Error",
          description: error.message || "Failed to save expense",
        });
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-8">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">
            {isEditing ? "Edit Expense" : "New Expense"}
          </h1>
          <p className="text-muted-foreground">
            {isEditing ? "Update your expense details" : "Create a new expense claim"}
          </p>
        </div>
        <div className="flex gap-2">
          <Button
            variant="outline"
            onClick={() => navigate("/expenses")}
            disabled={loading}
          >
            Cancel
          </Button>
          <Button
            onClick={() => saveExpense("draft")}
            disabled={loading}
          >
            <Save className="mr-2 h-4 w-4" />
            Save Draft
          </Button>
          <Button
            onClick={() => saveExpense("submitted")}
            disabled={loading || lineItems.length === 0}
          >
            <Send className="mr-2 h-4 w-4" />
            Submit
          </Button>
        </div>
      </div>

      <div className="grid gap-6 md:grid-cols-2">
        {/* Expense Details */}
        <Card>
          <CardHeader>
            <CardTitle>Expense Details</CardTitle>
            <CardDescription>Basic information about your expense</CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-2">
              <Label htmlFor="title">Title *</Label>
              <Input
                id="title"
                value={expense.title}
                onChange={(e) => setExpense({ ...expense, title: e.target.value })}
                placeholder="e.g., Business Trip to New York"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="destination">Destination *</Label>
              <Input
                id="destination"
                value={expense.destination}
                onChange={(e) => setExpense({ ...expense, destination: e.target.value })}
                placeholder="e.g., New York, NY"
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Start Date *</Label>
                <Popover>
                  <PopoverTrigger asChild>
                    <Button
                      variant="outline"
                      className={cn(
                        "w-full justify-start text-left font-normal",
                        !expense.trip_start && "text-muted-foreground"
                      )}
                    >
                      <CalendarIcon className="mr-2 h-4 w-4" />
                      {expense.trip_start ? format(expense.trip_start, "PPP") : "Pick a date"}
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0">
                    <Calendar
                      mode="single"
                      selected={expense.trip_start}
                      onSelect={(date) => date && setExpense({ ...expense, trip_start: date })}
                      initialFocus
                    />
                  </PopoverContent>
                </Popover>
              </div>

              <div className="space-y-2">
                <Label>End Date *</Label>
                <Popover>
                  <PopoverTrigger asChild>
                    <Button
                      variant="outline"
                      className={cn(
                        "w-full justify-start text-left font-normal",
                        !expense.trip_end && "text-muted-foreground"
                      )}
                    >
                      <CalendarIcon className="mr-2 h-4 w-4" />
                      {expense.trip_end ? format(expense.trip_end, "PPP") : "Pick a date"}
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0">
                    <Calendar
                      mode="single"
                      selected={expense.trip_end}
                      onSelect={(date) => date && setExpense({ ...expense, trip_end: date })}
                      initialFocus
                    />
                  </PopoverContent>
                </Popover>
              </div>
            </div>

            <div className="space-y-2">
              <Label htmlFor="purpose">Purpose</Label>
              <Textarea
                id="purpose"
                value={expense.purpose}
                onChange={(e) => setExpense({ ...expense, purpose: e.target.value })}
                placeholder="Describe the purpose of this trip..."
                rows={3}
              />
            </div>
          </CardContent>
        </Card>

        {/* Line Items */}
        <Card>
          <CardHeader>
            <div className="flex justify-between items-center">
              <div>
                <CardTitle>Expense Items</CardTitle>
                <CardDescription>Add individual expense items</CardDescription>
              </div>
              <Button onClick={addLineItem} size="sm">
                <Plus className="mr-2 h-4 w-4" />
                Add Item
              </Button>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            {lineItems.length === 0 ? (
              <p className="text-muted-foreground text-center py-8">
                No expense items yet. Click "Add Item" to get started.
              </p>
            ) : (
              <>
                {lineItems.map((item, index) => (
                  <div key={index} className="border rounded-lg p-4 space-y-3">
                    <div className="flex justify-between items-center">
                      <h4 className="font-medium">Item {index + 1}</h4>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => removeLineItem(index)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>

                    <div className="grid grid-cols-2 gap-3">
                      <div className="space-y-2">
                        <Label>Date</Label>
                        <Popover>
                          <PopoverTrigger asChild>
                            <Button
                              variant="outline"
                              className={cn(
                                "w-full justify-start text-left font-normal",
                                !item.date && "text-muted-foreground"
                              )}
                            >
                              <CalendarIcon className="mr-2 h-4 w-4" />
                              {item.date ? format(item.date, "PPP") : "Pick a date"}
                            </Button>
                          </PopoverTrigger>
                          <PopoverContent className="w-auto p-0">
                            <Calendar
                              mode="single"
                              selected={item.date}
                              onSelect={(date) => date && updateLineItem(index, "date", date)}
                              initialFocus
                            />
                          </PopoverContent>
                        </Popover>
                      </div>

                      <div className="space-y-2">
                        <Label>Category</Label>
                        <Select
                          value={item.category}
                          onValueChange={(value) => updateLineItem(index, "category", value)}
                        >
                          <SelectTrigger>
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            <SelectItem value="travel">Travel</SelectItem>
                            <SelectItem value="lodging">Lodging</SelectItem>
                            <SelectItem value="food">Food</SelectItem>
                            <SelectItem value="other">Other</SelectItem>
                          </SelectContent>
                        </Select>
                      </div>
                    </div>

                    <div className="space-y-2">
                      <Label>Description *</Label>
                      <Input
                        value={item.description}
                        onChange={(e) => updateLineItem(index, "description", e.target.value)}
                        placeholder="Describe this expense..."
                      />
                    </div>

                    <div className="space-y-2">
                      <Label>Amount *</Label>
                      <Input
                        type="number"
                        step="0.01"
                        min="0"
                        value={item.amount || ""}
                        onChange={(e) => updateLineItem(index, "amount", parseFloat(e.target.value) || 0)}
                        placeholder="0.00"
                      />
                    </div>
                  </div>
                ))}

                <div className="border-t pt-4">
                  <div className="flex justify-between items-center text-lg font-semibold">
                    <span>Total Amount:</span>
                    <span>${calculateTotal().toFixed(2)}</span>
                  </div>
                </div>
              </>
            )}
          </CardContent>
        </Card>
      </div>

      {/* File Upload Section */}
      {(currentExpenseId || isEditing) && (
        <div className="mt-8">
          <FileUpload 
            expenseId={currentExpenseId || id!} 
            onUploadComplete={() => {
              toast({
                title: "Receipt uploaded",
                description: "Receipt has been attached to this expense",
              });
            }}
          />
        </div>
      )}
    </div>
  );
}
