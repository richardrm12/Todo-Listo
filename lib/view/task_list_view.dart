import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_listo/model/task.dart';
import 'package:todo_listo/theme.dart';
import 'package:todo_listo/view/add_subtask_dialog.dart';
import 'package:todo_listo/view/add_task_dialog.dart';
import 'package:todo_listo/view/edit_subtask_dialog.dart';
import 'package:todo_listo/view/edit_task_dialog.dart';
import 'package:todo_listo/viewmodel/task_view_model.dart';

class TodoListView extends StatelessWidget {
  const TodoListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todo Listo'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Consumer<TaskViewModel>(
              builder: (context, viewModel, child) => SearchBar(
                onChanged: viewModel.setSearchQuery,
                leading: const Icon(Icons.search),
                hintText: 'Buscar tareas...',
              ),
            ),
          ),
        ),
        actions: [
          Consumer<TaskViewModel>(
            builder: (context, viewModel, child) {
              return PopupMenuButton(
                icon: const Icon(Icons.filter_list),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Mostrar completadas'),
                            Switch(
                              value: viewModel.showCompleted,
                              onChanged: (value) {
                                viewModel.setShowCompleted(value);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                        Text(
                          'Completadas: ${viewModel.completedTasks.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          'Pendientes: ${viewModel.pendingTasks.length}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    enabled: false,
                    child: Divider(height: 1),
                  ),
                  const PopupMenuItem(
                    enabled: false,
                    child: Text('Prioridad',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        )),
                  ),
                  ...TaskPriority.values.map((p) => PopupMenuItem(
                        child: ListTile(
                          leading: Radio<TaskPriority>(
                            value: p,
                            groupValue: viewModel.filterPriority,
                            onChanged: (value) {
                              viewModel.setFilterPriority(value);
                              Navigator.pop(context);
                            },
                          ),
                          title: Text(p.toString().split('.').last),
                          onTap: () {
                            viewModel.setFilterPriority(p);
                            Navigator.pop(context);
                          },
                        ),
                      )),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Radio<TaskPriority?>(
                        value: null,
                        groupValue: viewModel.filterPriority,
                        onChanged: (value) {
                          viewModel.setFilterPriority(null);
                          Navigator.pop(context);
                        },
                      ),
                      title: const Text('Todas las prioridades'),
                      onTap: () {
                        viewModel.setFilterPriority(null);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.tasks.isEmpty) {
            return const Center(
              child: Text('No hay tareas aun'),
            );
          }

          return Column(
            children: [
              // Agregar tooltip
              Container(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '← Desliza una tarea hacia la izquierda para eliminarla',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.tasks.length,
                  itemBuilder: (context, index) {
                    final task = viewModel.tasks[index];
                    return Dismissible(
                      key: Key(task.id),
                      direction: DismissDirection
                          .endToStart, // Solo permitir deslizar hacia la izquierda
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      onDismissed: (direction) {
                        viewModel.deleteTask(task.id);

                        // Mostrar Snackbar con opción de deshacer
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Tarea "${task.title}" eliminada'),
                            action: SnackBarAction(
                              label: 'Deshacer',
                              onPressed: () {
                                viewModel.undoDeleteTask();
                              },
                            ),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        // Añadir color de fondo para tareas completadas
                        color: task.isCompleted
                            ? Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                            : null,
                        child: ExpansionTile(
                          title: Text(
                            task.title,
                            style: TextStyle(
                              decoration: task.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: task.isCompleted ? Colors.grey : null,
                            ),
                          ),
                          leading: Checkbox(
                            value: task.isCompleted,
                            onChanged: (_) =>
                                viewModel.toggleTaskStatus(task.id),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => EditTodoDialog(todo: task),
                                  );
                                },
                              ),
                              const Icon(Icons.expand_more),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.description.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(task.description),
                                ),
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(
                                            context, task.priority),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        task.priority
                                            .toString()
                                            .split('.')
                                            .last,
                                        style: const TextStyle(
                                            color: Colors.white, fontSize: 12),
                                      ),
                                    ),
                                    if (task.dueDate != null) ...[
                                      const SizedBox(width: 8),
                                      Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: _isOverdue(task.dueDate!)
                                            ? Colors.red
                                            : Colors.grey,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _formatDate(task.dueDate!),
                                        style: TextStyle(
                                          color: _isOverdue(task.dueDate!)
                                              ? Colors.red
                                              : Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          children: [
                            // Subtasks
                            ...task.subtasks.map((subtask) => ListTile(
                                  leading: Checkbox(
                                    value: subtask.isCompleted,
                                    onChanged: (_) => viewModel.toggleSubtask(
                                      task.id,
                                      subtask.id,
                                    ),
                                  ),
                                  title: Text(subtask.title),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit),
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (_) => EditSubtaskDialog(
                                              taskId: task.id,
                                              subtask: subtask,
                                            ),
                                          );
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () {
                                          viewModel.deleteSubtask(
                                              task.id, subtask.id);
                                        },
                                      ),
                                    ],
                                  ),
                                )),
                            ListTile(
                              leading: const Icon(Icons.add),
                              title: const Text('Add subtask'),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      AddSubtaskDialog(taskId: task.id),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => const AddTaskDialog(),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getPriorityColor(BuildContext context, TaskPriority priority) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppTheme.getPriorityColor(priority, isDark);
  }

  bool _isOverdue(DateTime dueDate) {
    return dueDate.isBefore(DateTime.now());
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
