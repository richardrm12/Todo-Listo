import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_listo/viewmodel/task_view_model.dart';
import 'package:todo_listo/view/task_list_view.dart';
import 'package:todo_listo/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TaskViewModel(),
      child: MaterialApp(
        title: 'Todo Listo',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Usa el tema del sistema
        home: const TodoListView(),
      ),
    );
  }
}
