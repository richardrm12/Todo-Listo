import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_listo/model/task.dart';
import 'package:todo_listo/viewmodel/task_view_model.dart';

class AddTaskDialog extends StatefulWidget {
  const AddTaskDialog({super.key});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;
  TaskPriority _priority = TaskPriority.Medium;
  bool _showTitleError = false;
  bool _showDateError = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Tarea'),
      contentPadding: const EdgeInsets.all(16.0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Titulo',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                errorText:
                    _showTitleError ? 'El titulo no puede estar vacio' : null,
                counterText:
                    '${_titleController.text.length}/${Task.maxTitleLength}',
              ),
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.next,
              maxLines: 1,
              maxLength: Task.maxTitleLength.toInt(),
              onChanged: (value) {
                setState(() {
                  if (value.contains('\n')) {
                    _titleController.text = value.replaceAll('\n', '').trim();
                    _titleController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _titleController.text.length),
                    );
                  }
                  if (_showTitleError) {
                    _showTitleError = false;
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descripcion',
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                counterText:
                    '${_descriptionController.text.length}/${Task.maxDescriptionLength}',
              ),
              maxLines: 3,
              maxLength: Task.maxDescriptionLength.toInt(),
              keyboardType: TextInputType.text,
              onChanged: (value) {
                setState(() {
                  if (value.contains('\n')) {
                    _descriptionController.text =
                        value.replaceAll('\n', ' ').trim();
                    _descriptionController.selection =
                        TextSelection.fromPosition(
                      TextPosition(offset: _descriptionController.text.length),
                    );
                  }
                });
              },
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TaskPriority>(
                  isExpanded: true,
                  value: _priority,
                  items: TaskPriority.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(p.toString().split('.').last),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _priority = value);
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: _showDateError ? Colors.red : Colors.grey,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: ElevatedButton.icon(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      _dueDate = date;
                      _showDateError = false;
                    });
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(
                  _dueDate == null
                      ? 'Fecha limite'
                      : 'Fecha limite: ${_dueDate.toString().split(' ')[0]}',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  alignment: Alignment.centerLeft,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            if (_showDateError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 12),
                child: Text(
                  'Fecha limite requerida',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    bool hasError = false;

                    if (_titleController.text.isEmpty) {
                      setState(() => _showTitleError = true);
                      hasError = true;
                    }

                    if (_dueDate == null) {
                      setState(() => _showDateError = true);
                      hasError = true;
                    }

                    if (_descriptionController.text.length >
                        Task.maxDescriptionLength) {
                      hasError = true;
                    }

                    if (hasError) return;

                    Provider.of<TaskViewModel>(context, listen: false).addTask(
                      '',
                      '',
                      title: _titleController.text.trim(),
                      description: _descriptionController.text.trim(),
                      dueDate: _dueDate,
                      priority: _priority,
                    );
                    Navigator.pop(context);
                  },
                  child: const Text('Crear'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
