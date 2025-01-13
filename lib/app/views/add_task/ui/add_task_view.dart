import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task_manager/app/global/button.dart';
import 'package:task_manager/app/global/textfields.dart';
import 'package:task_manager/app/models/task_model.dart';
import 'package:task_manager/app/services/auth_service.dart';
import 'package:task_manager/app/utils/color.dart';
import 'package:task_manager/app/utils/styles.dart';
import 'package:task_manager/app/views/add_task/controller/add_task_controller.dart';

class AddTaskView extends StatefulWidget {
  final Task? task;
  const AddTaskView({super.key, this.task});

  @override
  State<AddTaskView> createState() => _AddTaskViewState();
}

class _AddTaskViewState extends State<AddTaskView> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authService = Get.put(AuthService());
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TaskPriority _selectedPriority;
  final controller = Get.put(AddTaskController());

  @override
  void initState() {
    super.initState();
    // Initialize with existing task data if editing
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _selectedDate = widget.task!.dueDate;
      _selectedTime = TimeOfDay.fromDateTime(widget.task!.dueDate);
      _selectedPriority = widget.task!.priority;
    } else {
      // Initialize with default values for new task
      final Map<String, dynamic>? args = Get.arguments;
      _selectedDate = args?['selectedDate'] ?? DateTime.now();
      _selectedTime = TimeOfDay.now();
      _selectedPriority = TaskPriority.medium;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Appcolors.white,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          widget.task != null ? 'Edit Task' : 'Add Task',
          style: style(18, FontWeight.w500, Appcolors.white),
        ),
        backgroundColor: Appcolors.primary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFields(
                hintText: 'Enter title',
                label: 'Title',
                controller: _titleController,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFields(
                  hintText: 'Enter description',
                  label: 'Description',
                  controller: _descriptionController,
                  length: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          fillColor: Appcolors.white,
                          labelText: 'Due Date',
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Appcolors.borderColor, width: 1.0),
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                        child: Text(
                            DateFormat('MMM dd, yyyy').format(_selectedDate)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: _selectTime,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                            labelText: 'Time',
                            border: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color: Appcolors.borderColor, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            )),
                        child: Text(_selectedTime.format(context)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TaskPriority>(
                value: _selectedPriority,
                decoration: const InputDecoration(
                    fillColor: Appcolors.white,
                    labelText: 'Priority',
                    border: OutlineInputBorder(
                      borderSide:
                          BorderSide(color: Appcolors.borderColor, width: 1.0),
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    )),
                items: TaskPriority.values.map((priority) {
                  return DropdownMenuItem(
                    value: priority,
                    child: Row(
                      children: [
                        Icon(_getPriorityIcon(priority),
                            color: _getPriorityColor(priority)),
                        const SizedBox(width: 8),
                        Text(priority.toString().split('.').last),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (TaskPriority? value) {
                  if (value != null) {
                    setState(() => _selectedPriority = value);
                  }
                },
              ),
              const SizedBox(height: 24),
              GestureDetector(
                  onTap: _saveTask,
                  child: Button(
                    text: widget.task != null ? 'Update Task' : 'Save Task',
                  ))
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  IconData _getPriorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Icons.priority_high;
      case TaskPriority.medium:
        return Icons.arrow_upward;
      case TaskPriority.low:
        return Icons.arrow_downward;
    }
  }

  Color _getPriorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.high:
        return Appcolors.red;
      case TaskPriority.medium:
        return Appcolors.lightBlue;
      case TaskPriority.low:
        return Appcolors.green;
    }
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      try {
        final dueDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final task = Task(
          id: widget.task?.id ??
              DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          dueDate: dueDate,
          priority: _selectedPriority,
          status: widget.task?.status ?? TaskStatus.pending,
          userId: _authService.user.value?.uid ?? '',
        );

        bool success;
        if (widget.task != null) {
          success = await controller.updateTask(task);
        } else {
          success = await controller.addTask(task);
        }

        if (success) {
          Get.back();
          Get.snackbar(
            'Success',
            'Task ${widget.task != null ? 'updated' : 'added'} successfully',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Appcolors.green,
            colorText: Appcolors.white,
          );
        }
      } catch (e) {
        log('Error saving task: $e');
        Get.back();
        Get.snackbar(
          'Warning',
          'Task saved but there might be sync issues',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Appcolors.red,
          colorText: Appcolors.white,
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
