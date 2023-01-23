import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'ExpenseListModel.dart';
import 'expense.dart';

void main() {
  final expenses = ExpenseListModel();

  runApp(ScopedModel<ExpenseListModel>(
    model: expenses,
    child: const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Ledger',
      theme: ThemeData( primarySwatch: Colors.green ),
      home: const MyHomePage( title: 'Expense calculator' ),
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( title: Text(title) ),
      body: ScopedModelDescendant<ExpenseListModel>(
          builder: (context, child, expenses) {
            return ListView.separated(
              itemCount: expenses.items.length + 1,
              itemBuilder: (context, index){
                if (index == 0) {
                  return ListTile(
                      title: Text(
                        "Total expenses: " + expenses.totalExpense.toString(),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ));
                } else {
                  index = index - 1;
                  return Dismissible(
                    key: Key(expenses.items[index].id.toString()),
                    onDismissed: (direction) {
                      expenses.delete(expenses.items[index]);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Item with id, "
                          + expenses.items[index].id.toString()
                          + " is dismissed")
                        )
                      );
                    },
                    child: ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FormPage(
                              id: expenses.items[index].id,
                              expenses: expenses,
                            )
                          )
                        );
                      },
                      leading: const Icon(Icons.monetization_on),
                      trailing: const Icon(Icons.keyboard_arrow_right),
                      title: Text(expenses.items[index].category
                      + ": " + expenses.items[index].amount.toString()
                      + " \nspent on " + expenses.items[index].formattedDate,
                      style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic),)
                    )
                  );
                }
              },
              separatorBuilder: (context, index) {
                return const Divider();
              },
            );
      }),
      floatingActionButton: ScopedModelDescendant<ExpenseListModel>(
        builder: (context, child, expenses) {
          return FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ScopedModelDescendant<ExpenseListModel>(
                        builder: (context, child, expenses) {
                          return FormPage(id: 0, expenses: expenses);
                        }))
              );
            },
            tooltip: 'Enter Expense',
            child: const Icon(Icons.add),
          );
        }
      ),
    );
  }
}

class FormPage extends StatefulWidget {
  const FormPage({super.key, required this.id, required this.expenses});

  final int id;
  final ExpenseListModel expenses;

  @override
  _FormPageState createState() => _FormPageState(id: id, expenses: expenses);
}

class _FormPageState extends State<FormPage> {
  _FormPageState({required this.id, required this.expenses});

  final int id;
  final ExpenseListModel expenses;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final formKey = GlobalKey<FormState>();

  double _amount = 0.0;
  DateTime _date = DateTime.now();
  String _category = "groceries";

  void _submit() {
    final form = formKey.currentState;

    form?.validate();
    form?.save();

      if (id == 0) { expenses.add(Expense(0, _amount, _date, _category)); }
      else { expenses.update(Expense(id, _amount, _date, _category)); }

      Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar( title: const Text('Enter expense details'), ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: formKey,
          child: Column(
            children:[
              TextFormField(
                style: const TextStyle(fontSize: 22),
                decoration: const InputDecoration(
                  icon: Icon(Icons.monetization_on),
                  labelText: 'Amount', labelStyle: TextStyle(fontSize: 18),
                ),
                validator: (val) {
                  Pattern pattern = r'^[1-9]\d*(\.\d+)?$';
                  RegExp regex = RegExp(pattern.toString());
                  if (!regex.hasMatch(val.toString())) { return 'Enter a valid number'; }
                  else { return null; }
                },
                initialValue:
                  id == 0 ? '' : expenses.byId(id)?.amount.toString(),
                onSaved: (val) => _amount = double.parse(val.toString()),
              ),
              TextFormField(
                style: const TextStyle( fontSize: 22 ),
                decoration: const InputDecoration(
                  icon: Icon(Icons.calendar_today),
                  hintText: 'Enter date',
                  labelText: 'Date',
                  labelStyle: TextStyle( fontSize: 18 ),
                ),
                validator: (val) {
                  Pattern pattern = r'^((?:19|20)\d\d)[- /.](0[1-9]|[12][0-9]|3[01])$';
                  RegExp regex = RegExp(pattern.toString());
                  if (!regex.hasMatch(val.toString())) { return 'Enter a valid date'; }
                  else { return null; }
                },
                onSaved: (val) => _date = DateTime.parse(val.toString()),
                initialValue:
                  id == 0 ? '' : expenses.byId(id)?.formattedDate,
                keyboardType: TextInputType.datetime,
              ),
              TextFormField(
                style: const TextStyle(fontSize: 22),
                decoration: const InputDecoration(
                  icon: Icon( Icons.category ),
                  labelText: 'Category',
                  labelStyle: TextStyle( fontSize: 18 )
                ),
                onSaved: (val) => _category = val.toString(),
                initialValue:
                  id == 0 ? '' : expenses.byId(id)?.category.toString(),
              ),
              ElevatedButton(
                onPressed: _submit,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}