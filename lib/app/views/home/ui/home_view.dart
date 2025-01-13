import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:task_manager/app/models/task_model.dart';
import 'package:task_manager/app/routes/app_routes.dart';
import 'package:task_manager/app/services/connectivity_service.dart';
import 'package:task_manager/app/utils/color.dart';
import 'package:task_manager/app/utils/styles.dart';
import 'package:get/get.dart';
import 'package:task_manager/app/views/add_task/ui/add_task_view.dart';
import 'package:task_manager/app/views/home/controller/home_controller.dart';
import 'package:task_manager/theme_controller.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _controller = Get.put(HomeController());
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  RxList<String> selectedTaskIds = <String>[].obs;
  @override
  void initState() {
    super.initState();

    Get.put(ConnectivityService());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Obx(() => Column(
            children: [
              _buildStatisticsSection(),
              _buildCalendarSection(),
              _buildTaskList(),
            ],
          )),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final themeController = Get.put(ThemeController());

    return AppBar(
      backgroundColor: Appcolors.primary,
      centerTitle: true,
      title: Text(
        'Task Manager',
        style: style(18, FontWeight.w500, Appcolors.white),
      ),
      leading: IconButton(
        icon: Icon(
          Icons.brightness_6,
          color: Appcolors.white,
        ),
        onPressed: () {
          themeController
              .toggleTheme(); // This should update the theme immediately
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.sync, color: Appcolors.white),
          onPressed: () => _controller.syncAllTasks(),
          tooltip: 'Sync all tasks',
        ),
        IconButton(
          icon: Obx(() => Stack(
                children: [
                  const Icon(Icons.filter_list, color: Appcolors.white),
                  if (_controller.appliedFiltersCount > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Appcolors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_controller.appliedFiltersCount}',
                          style: const TextStyle(
                            color: Appcolors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              )),
          onPressed: _showFilterOptions,
        ),
        IconButton(
          onPressed: () {
            _controller.logout();
          },
          icon: Icon(Icons.logout_outlined, color: Appcolors.white),
        ),
      ],
    );
  }

  Widget _buildStatisticsSection() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            'Task Statistics',
            style: style(16, FontWeight.bold, Appcolors.primary),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(
                  'Pending', _controller.pendingTasks.value, Appcolors.red),
              _buildStatCard('In Progress', _controller.inProgressTasks.value,
                  Appcolors.lightBlue),
              _buildStatCard('Completed', _controller.completedTasks.value,
                  Appcolors.green),
            ],
          ),
          const SizedBox(height: 8),
          _buildOverdueCard(),
        ],
      ),
    );
  }

  Widget _buildOverdueCard() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, color: Colors.red.shade700),
            const SizedBox(width: 8),
            Text(
              '${_controller.overdueTasks.value} Overdue Tasks',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Calendar View',
                  style: style(16, FontWeight.bold, Appcolors.primary),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                  onPressed: () => _addTaskForSelectedDate(),
                ),
              ],
            ),
          ),
          TableCalendar<Task>(
            firstDay: DateTime.now().subtract(const Duration(days: 365)),
            lastDay: DateTime.now().add(const Duration(days: 365)),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            eventLoader: _getTasksForDay,
            onDaySelected: _onDaySelected,
            calendarFormat: CalendarFormat.week,
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Appcolors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return Expanded(
      child: Obx(() {
        final tasks = _controller.filteredTasks;
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return _buildTaskTile(task);
          },
        );
      }),
    );
  }

  Widget _buildTaskTile(Task task) {
    return ListTile(
      leading: _getPriorityIcon(task.priority),
      title: Text(
        task.title,
        style: TextStyle(
          decoration: task.status == TaskStatus.completed
              ? TextDecoration.lineThrough
              : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(DateFormat('MMM dd, yyyy').format(task.dueDate)),
          if (!task.isSynced)
            Row(
              children: [
                Icon(Icons.sync_problem, size: 16, color: Appcolors.red),
                const SizedBox(width: 4),
                Text(
                  'Not synced',
                  style: TextStyle(
                    color: Appcolors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!task.isSynced)
            IconButton(
              icon: Icon(Icons.sync, color: Appcolors.lightBlue),
              onPressed: () => _controller.syncTask(task),
              tooltip: 'Sync task',
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text('Edit'),
                onTap: () => _editTask(task),
              ),
              PopupMenuItem(
                child: Text('Delete'),
                onTap: () => _deleteTask(task),
              ),
            ],
          ),
        ],
      ),
      onTap: () => _showTaskDetails(task),
    );
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    _controller.filterTasksByDate(selectedDay);
  }

  List<Task> _getTasksForDay(DateTime day) {
    return _controller.getTasksForDay(day);
  }

  void _addTaskForSelectedDate() {
    Get.toNamed(AppRoutes.addtask, arguments: {'selectedDate': _selectedDay});
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getPriorityIcon(TaskPriority priority) {
    final IconData icon;
    final Color color;

    switch (priority) {
      case TaskPriority.high:
        icon = Icons.priority_high;
        color = Appcolors.red;
        break;
      case TaskPriority.medium:
        icon = Icons.arrow_upward;
        color = Appcolors.lightBlue;
        break;
      case TaskPriority.low:
        icon = Icons.arrow_downward;
        color = Appcolors.green;
        break;
    }

    return Icon(icon, color: color);
  }

  void _editTask(Task task) {
    Get.to(() => AddTaskView(task: task));
  }

  void _showTaskDetails(Task task) {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            _getPriorityIcon(task.priority),
            const SizedBox(width: 8),
            Expanded(child: Text(task.title)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(),
              Text('Description:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              Text(task.description),
              const SizedBox(height: 8),
              Text('Due Date:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(DateFormat('MMM dd, yyyy HH:mm').format(task.dueDate)),
              const SizedBox(height: 8),
              Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildStatusDropdown(task),
              if (!task.isSynced)
                Row(
                  children: [
                    Icon(Icons.sync_problem, size: 16, color: Appcolors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Not synced',
                      style: TextStyle(
                        color: Appcolors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _editTask(task);
            },
            child: const Text('Edit'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown(Task task) {
    return DropdownButton<TaskStatus>(
      value: task.status,
      onChanged: (TaskStatus? newStatus) {
        if (newStatus != null) {
          _controller.updateTaskStatus(task, newStatus);
          Get.back();
        }
      },
      items: TaskStatus.values.map((TaskStatus status) {
        return DropdownMenuItem<TaskStatus>(
          value: status,
          child: Text(status.toString().split('.').last),
        );
      }).toList(),
    );
  }

  void _deleteTask(Task task) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _controller.deleteTask(task.id);
              Get.back();
              Get.snackbar(
                'Success',
                'Task deleted successfully',
                backgroundColor: Appcolors.green,
                colorText: Appcolors.white,
              );
            },
            child: const Text('Delete', style: TextStyle(color: Appcolors.red)),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    Get.bottomSheet(
      SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Spacer(),
                  Text('Filter & Sort Tasks',
                      style: style(18, FontWeight.bold, Appcolors.primary)),
                  Spacer(),
                  GestureDetector(
                    onTap: () => Get.back(),
                    child: Icon(Icons.close, color: Appcolors.black),
                  )
                ],
              ),
              const Divider(),
              _buildMultiFilterSection(),
              const Divider(),
              _buildSortSection(),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  _controller.clearFilters();
                  Get.back();
                },
                child: const Text('Clear All Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMultiFilterSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status', style: TextStyle(fontWeight: FontWeight.bold)),
        Obx(() => Wrap(
              spacing: 8,
              children: TaskStatus.values.map((status) {
                return FilterChip(
                  label: Text(status.toString().split('.').last),
                  selected: _controller.selectedStatuses.contains(status),
                  onSelected: (selected) {
                    _controller.toggleStatusFilter(status);
                  },
                );
              }).toList(),
            )),
        const SizedBox(height: 8),
        const Text('Priority', style: TextStyle(fontWeight: FontWeight.bold)),
        Obx(() => Wrap(
              spacing: 8,
              children: TaskPriority.values.map((priority) {
                return FilterChip(
                  label: Text(priority.toString().split('.').last),
                  selected: _controller.selectedPriorities.contains(priority),
                  onSelected: (selected) {
                    _controller.togglePriorityFilter(priority);
                  },
                );
              }).toList(),
            )),
      ],
    );
  }

  Widget _buildSortSection() {
    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Sort By',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Due Date'),
                  selected: _controller.sortBy.value == 'dueDate',
                  onSelected: (selected) {
                    if (selected) {
                      _controller.updateSorting(
                          'dueDate', _controller.isDescending.value);
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('Created Date'),
                  selected: _controller.sortBy.value == 'createdAt',
                  onSelected: (selected) {
                    if (selected) {
                      _controller.updateSorting(
                          'createdAt', _controller.isDescending.value);
                    }
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Text('Order:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                ToggleButtons(
                  isSelected: [
                    !_controller.isDescending.value,
                    _controller.isDescending.value
                  ],
                  onPressed: (index) {
                    _controller.updateSorting(
                        _controller.sortBy.value, index == 1);
                  },
                  children: const [
                    Icon(Icons.arrow_upward),
                    Icon(Icons.arrow_downward),
                  ],
                ),
              ],
            ),
          ],
        ));
  }
}
