import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo_listo/viewmodel/task_view_model.dart';
import 'package:todo_listo/model/task.dart';

class EditSubtaskDialog extends StatefulWidget {
  final String taskId;
  final Subtask subtask;

  const EditSubtaskDialog({
    super.key,
    required this.taskId,
    required this.subtask,
  });

  @override
  State<EditSubtaskDialog> createState() => _EditSubtaskDialogState();
}

class _EditSubtaskDialogState extends State<EditSubtaskDialog> {
  late TextEditingController _titleController;
  bool _showTitleError = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.subtask.title);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Subtarea'),
      content: TextField(
        controller: _titleController,
        decoration: InputDecoration(
          labelText: 'Titulo',
          errorText: _showTitleError ? 'El itulo no puede estar vacio' : null,
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
            // Llamar al viewModel para editar la subtarea
            Provider.of<TaskViewModel>(context, listen: false).editSubtask(
                widget.taskId, widget.subtask.id, _titleController.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save'),
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
