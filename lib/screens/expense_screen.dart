import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../models/deduction.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> {
  late Box<Expense> _expenseBox;
  late Box<Budget> _budgetBox;
  late Box<Deduction> _deductionBox;

  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

  final List<String> _categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Health',
    'Entertainment',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _expenseBox = Hive.box<Expense>('expenses');
    _budgetBox = Hive.box<Budget>('budget');
    _deductionBox = Hive.box<Deduction>('deductions');
    _ensureMonthDataExists();
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_selectedMonth);

  void _ensureMonthDataExists() {
    // If no budget for this month, copy from previous month if it exists
    final hasBudget = _budgetBox.values.any((b) => b.monthKey == _monthKey);
    final hasDeductions = _deductionBox.values.any((d) => d.monthKey == _monthKey);

    if (!hasBudget && !hasDeductions) {
      final prevDate = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      final prevKey = DateFormat('yyyy-MM').format(prevDate);
      
      final prevBudget = _budgetBox.values.where((b) => b.monthKey == prevKey);
      if (prevBudget.isNotEmpty) {
        _budgetBox.add(Budget(amount: prevBudget.first.amount, label: 'Base Salary', monthKey: _monthKey));
      }

      final prevDeds = _deductionBox.values.where((d) => d.monthKey == prevKey);
      for (final d in prevDeds) {
        _deductionBox.add(Deduction(id: DateTime.now().toString(), title: d.title, amount: d.amount, monthKey: _monthKey));
      }
    }
  }

  // --- Data Getters ---

  Budget? get _currentBudget {
    try {
      return _budgetBox.values.firstWhere((b) => b.monthKey == _monthKey);
    } catch (_) {
      return null;
    }
  }

  double get _baseSalary => _currentBudget?.amount ?? 0;

  List<Deduction> get _currentDeductions {
    return _deductionBox.values.where((d) => d.monthKey == _monthKey).toList();
  }

  double get _totalDeductions {
    return _currentDeductions.fold(0.0, (sum, d) => sum + d.amount);
  }

  double get _netBudget => _baseSalary - _totalDeductions;

  List<Expense> get _currentMonthExpenses {
    return _expenseBox.values.where((e) {
      return e.date.year == _selectedMonth.year && e.date.month == _selectedMonth.month;
    }).toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  double get _totalExpenses {
    return _currentMonthExpenses.fold(0.0, (sum, e) => sum + e.amount);
  }

  double get _remaining => _netBudget - _totalExpenses;

  // --- Month Navigation ---
  void _changeMonth(int offset) {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + offset, 1);
      _ensureMonthDataExists();
    });
  }

  void _showMonthYearPicker() {
    int tempYear = _selectedMonth.year;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeBg = isDark ? Colors.white : Colors.black87;
    final activeText = isDark ? Colors.black : Colors.white;
    final defaultText = isDark ? Colors.white : Colors.black87;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setDialogState(() => tempYear--)),
              Text(tempYear.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setDialogState(() => tempYear++)),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: 12,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.5,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final monthNum = index + 1;
                final monthName = DateFormat('MMM').format(DateTime(tempYear, monthNum));
                final isSelected = _selectedMonth.year == tempYear && _selectedMonth.month == monthNum;
                
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    setState(() {
                      _selectedMonth = DateTime(tempYear, monthNum, 1);
                      _ensureMonthDataExists();
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? activeBg : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      monthName,
                      style: TextStyle(
                        color: isSelected ? activeText : defaultText,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // --- Income & Deductions Manager ---
  void _showIncomeDeductionManager() {
    final salaryCtrl = TextEditingController(
      text: _baseSalary > 0 ? _baseSalary.toString() : '',
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Income & Deductions', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              
              // Base Salary
              const Text('Base Salary / Budget', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: salaryCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor, fontSize: 18),
                      decoration: InputDecoration(
                        prefixText: '₱ ',
                        prefixStyle: const TextStyle(color: Colors.grey, fontSize: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      final val = double.tryParse(salaryCtrl.text.trim());
                      if (val != null && val >= 0) {
                        final b = _currentBudget;
                        if (b == null) {
                          _budgetBox.add(Budget(amount: val, label: 'Base Salary', monthKey: _monthKey));
                        } else {
                          b.amount = val;
                          b.save();
                        }
                        setState(() {});
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    ),
                    child: const Text('Update', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Fixed Deductions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Fixed Monthly Deductions', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  IconButton(
                    icon: const Icon(Icons.add_circle, color: Colors.black87),
                    onPressed: () => _showAddEditDeductionDialog(setSheetState),
                  )
                ],
              ),
              if (_currentDeductions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No fixed deductions added yet.', style: TextStyle(color: Colors.grey))),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _currentDeductions.length,
                  itemBuilder: (context, i) {
                    final d = _currentDeductions[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(d.title, style: TextStyle(color: textColor, fontWeight: FontWeight.normal)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('-₱${NumberFormat('#,##0.00').format(d.amount)}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 20),
                            onPressed: () => _showAddEditDeductionDialog(setSheetState, d),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                            onPressed: () {
                              d.delete();
                              setSheetState(() {});
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditDeductionDialog(StateSetter setSheetState, [Deduction? deduction]) {
    final titleCtrl = TextEditingController(text: deduction?.title ?? '');
    final amtCtrl = TextEditingController(
      text: deduction != null ? deduction.amount.toString() : '',
    );
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(deduction == null ? 'Add Deduction' : 'Edit Deduction'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title (e.g. SSS)')),
            TextField(controller: amtCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount (₱)')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amtCtrl.text.trim());
              final t = titleCtrl.text.trim();
              if (val != null && val > 0 && t.isNotEmpty) {
                if (deduction == null) {
                  _deductionBox.add(Deduction(id: DateTime.now().toString(), title: t, amount: val, monthKey: _monthKey));
                } else {
                  deduction.title = t;
                  deduction.amount = val;
                  deduction.save();
                }
                setSheetState(() {});
                setState(() {});
                Navigator.pop(ctx);
              }
            },
            child: Text(deduction == null ? 'Add' : 'Save'),
          ),
        ],
      ),
    );
  }

  // --- Add Expense ---
  void _showAddExpenseSheet() {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String selectedCategory = _categories.first;
    DateTime selectedDate = DateTime.now();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    showModalBottomSheet(
      context: context,
      backgroundColor: bgColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 40,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.3), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 20),
              Text('Record Expense', style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration('Title (e.g. Lunch)', textColor),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: textColor),
                decoration: _inputDecoration('Amount', textColor).copyWith(prefixText: '₱ ', prefixStyle: const TextStyle(color: Colors.grey)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                dropdownColor: bgColor,
                style: TextStyle(color: textColor),
                decoration: _inputDecoration('Category', textColor),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setSheetState(() => selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setSheetState(() => selectedDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.3))),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
                      const SizedBox(width: 10),
                      Text(DateFormat('MMM dd, yyyy').format(selectedDate), style: TextStyle(color: textColor)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final title = titleCtrl.text.trim();
                    final amount = double.tryParse(amountCtrl.text.trim());
                    if (title.isEmpty || amount == null || amount <= 0) return;

                    _expenseBox.add(Expense(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      title: title,
                      amount: amount,
                      category: selectedCategory,
                      date: selectedDate,
                    ));
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Expense', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, Color textColor) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.grey),
    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey.withOpacity(0.3))),
    focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
  );

  @override
  Widget build(BuildContext context) {
    final expenses = _currentMonthExpenses;
    final fmt = NumberFormat('#,##0.00');

    // Minimalist Colors
    const Color bg = Color(0xFFF7F8FA);
    const Color textPrimary = Color(0xFF1E1E1E);
    const Color textSecondary = Color(0xFF757575);
    const Color cardBg = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            // Month Navigator Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: textPrimary, size: 28),
                    onPressed: () => _changeMonth(-1),
                  ),
                  InkWell(
                    onTap: _showMonthYearPicker,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat('MMMM yyyy').format(_selectedMonth),
                            style: const TextStyle(color: textPrimary, fontSize: 20, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_drop_down, color: textPrimary),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: textPrimary, size: 28),
                    onPressed: () => _changeMonth(1),
                  ),
                ],
              ),
            ),
            
            // Minimalist Budget Summary Card
            GestureDetector(
              onTap: _showIncomeDeductionManager,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: textPrimary,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('REMAINING BUDGET', style: TextStyle(color: Colors.white60, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      '₱${fmt.format(_remaining)}',
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MinimalStat(label: 'NET INCOME', value: '₱${fmt.format(_netBudget)}'),
                        Container(width: 1, height: 30, color: Colors.white24),
                        _MinimalStat(label: 'SPENT', value: '₱${fmt.format(_totalExpenses)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Tap budget card to edit Salary & Deductions', style: TextStyle(color: textSecondary, fontSize: 11)),
            const SizedBox(height: 24),
            
            // Expense List
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
                ),
                child: expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 80, color: Colors.grey.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          const Text('No expenses this month', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 100),
                      physics: const BouncingScrollPhysics(),
                      itemCount: expenses.length,
                      separatorBuilder: (ctx, i) => Divider(color: Colors.grey.withOpacity(0.1), height: 24),
                      itemBuilder: (context, i) {
                        final expense = expenses[i];
                        return Dismissible(
                          key: Key(expense.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          ),
                          onDismissed: (_) {
                            expense.delete();
                            setState(() {});
                          },
                          child: Row(
                            children: [
                              Container(
                                width: 48, height: 48,
                                decoration: BoxDecoration(
                                  color: bg,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.attach_money, color: textPrimary),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(expense.title, style: const TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${expense.category} • ${DateFormat('MMM dd').format(expense.date)}',
                                      style: const TextStyle(color: textSecondary, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '-₱${fmt.format(expense.amount)}',
                                style: const TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExpenseSheet,
        backgroundColor: textPrimary,
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class _MinimalStat extends StatelessWidget {
  final String label;
  final String value;

  const _MinimalStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10, letterSpacing: 1.0, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
