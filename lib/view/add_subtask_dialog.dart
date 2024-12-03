import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_listo/viewmodel/task_view_model.dart';

class AddSubtaskDialog extends StatefulWidget {
  final String taskId;

  const AddSubtaskDialog({super.key, required this.taskId});

  @override
  State<AddSubtaskDialog> createState() => _AddSubtaskDialogState();
}

class _AddSubtaskDialogState extends State<AddSubtaskDialog> {
  final _titleController = TextEditingController();
  bool _showTitleError = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Subtarea'),
      content: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: 'Titulo',
          errorText: _showTitleError ? 'El titulo no puede estar vacio' : null,
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isEmpty) {
              setState(() => _showTitleError = true);
              return;
            }
            Provider.of<TaskViewModel>(context, listen: false)
                .addSubtask(widget.taskId, _titleController.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }
}
