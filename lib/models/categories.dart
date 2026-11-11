/// Expense categories shared by the add form, budgets, reports and export.
///
/// The first group are everyday spending categories (never tax-deductible);
/// the rest map to Malaysian LHDN relief categories.
const List<String> everydayExpenseCategories = [
  'Food & dining',
  'Groceries',
  'Transport',
  'Bills & utilities',
  'Shopping',
  'Entertainment',
];

const List<String> taxReliefExpenseCategories = [
  'Medical expenses',
  'Health screening',
  'Lifestyle',
  'Sports lifestyle',
  'Education fees',
  'Childcare fees',
  'SSPN net deposit',
  'Breastfeeding equipment',
  'EV charging / composting machine',
  'Housing loan interest',
  'Private Retirement Scheme',
  'Insurance',
  'Zakat',
  'Donation/Gift',
];

const List<String> expenseCategories = [
  ...everydayExpenseCategories,
  ...taxReliefExpenseCategories,
  'Others',
];
