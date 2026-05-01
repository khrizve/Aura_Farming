import 'package:flutter/material.dart';
import '../widgets/quest_card.dart';
import '../models/quest.dart';

class QuestScreen extends StatefulWidget {
  final List<Quest> quests;
  final Function(Quest) onQuestComplete;
  final Function(String) onQuestStarted;
  final Function(Quest) onQuestAdded;
  final Function(String) onQuestDeleted;

  const QuestScreen({
    Key? key,
    required this.quests,
    required this.onQuestComplete,
    required this.onQuestStarted,
    required this.onQuestAdded,
    required this.onQuestDeleted,
  }) : super(key: key);

  @override
  State<QuestScreen> createState() => _QuestScreenState();
}

class _QuestScreenState extends State<QuestScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = ['All', 'Available Now', 'Upcoming', 'Mind', 'Body', 'Spirit', 'Special', 'Custom'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  void _handleQuestComplete(Quest quest) {
    if (quest.isValidNow || quest.isTimedQuestCompleted()) {
      widget.onQuestComplete(quest);
    } else {
      _showNotAvailableDialog(quest);
    }
  }

  void _handleQuestStart(String questId) {
    final quest = widget.quests.firstWhere((q) => q.id == questId);
    if (quest.isValidNow) {
      widget.onQuestStarted(questId);
    } else {
      _showNotAvailableDialog(quest);
    }
  }

  void _showNotAvailableDialog(Quest quest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quest Not Available'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('"${quest.title}" is not available right now.'),
            const SizedBox(height: 12),
            if (quest.validTimeRange != null)
              Text('Available: ${quest.validTimeRange}'),
            if (quest.validDays != null && quest.validDays!.isNotEmpty)
              Text('Days: ${quest.validDays!.map((d) => d.name).join(", ")}'),
            const SizedBox(height: 12),
            Text('Status: ${quest.validationStatus}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleAddQuest() {
    _showAddQuestDialog();
  }

  void _showAddQuestDialog() {
    showDialog(
      context: context,
      builder: (context) => AddQuestDialog(
        onQuestAdded: (newQuest) {
          widget.onQuestAdded(newQuest);
        },
      ),
    );
  }

  List<Quest> _getFilteredQuests(String category) {
    if (category == 'All') return widget.quests;
    if (category == 'Available Now') {
      return widget.quests.where((quest) => quest.isValidNow && !quest.isCompleted).toList();
    }
    if (category == 'Upcoming') {
      return widget.quests.where((quest) => !quest.isValidNow && !quest.isCompleted).toList();
    }
    if (category == 'Custom') {
      return widget.quests.where((quest) => quest.category == 'Custom').toList();
    }
    return widget.quests.where((quest) => quest.category == category).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quests'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _categories.map((category) => Tab(text: category)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _handleAddQuest,
            tooltip: 'Add Custom Quest',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          final filteredQuests = _getFilteredQuests(category);
          return _buildQuestList(filteredQuests, category);
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleAddQuest,
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
        tooltip: 'Add Custom Quest',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildQuestList(List<Quest> quests, String category) {
    if (quests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category == 'Custom' ? Icons.add_task : 
              category == 'Upcoming' ? Icons.schedule : 
              category == 'Available Now' ? Icons.check_circle : Icons.assignment,
              size: 64,
              color: Colors.purple[300],
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyStateMessage(category),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyStateSubtitle(category),
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (category == 'Custom')
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: ElevatedButton(
                  onPressed: _handleAddQuest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[700],
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add Custom Quest'),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: quests.length,
        itemBuilder: (context, index) {
          final quest = quests[index];
          final canComplete = !quest.isCompleted && quest.isValidNow;
          
          return QuestCard(
            quest: quest,
            onComplete: () => _handleQuestComplete(quest),
            onStart: quest.isTimed && quest.startTime == null && quest.isValidNow
                ? () => _handleQuestStart(quest.id)
                : null,
            canComplete: canComplete,
            isCustom: quest.category == 'Custom',
            onDelete: quest.category == 'Custom' ? () => _handleDeleteQuest(quest) : null,
          );
        },
      ),
    );
  }

  String _getEmptyStateMessage(String category) {
    switch (category) {
      case 'Available Now':
        return 'No quests available at this time';
      case 'Upcoming':
        return 'No upcoming quests';
      case 'Custom':
        return 'No custom quests yet';
      default:
        return 'No quests available';
    }
  }

  String _getEmptyStateSubtitle(String category) {
    switch (category) {
      case 'Available Now':
        return 'Check back later or complete other quests first';
      case 'Upcoming':
        return 'New quests will appear based on time and day';
      case 'Custom':
        return 'Tap the + button to add your first custom quest!';
      default:
        return 'Complete more quests to unlock new ones!';
    }
  }

  void _handleDeleteQuest(Quest quest) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Quest'),
        content: Text('Are you sure you want to delete "${quest.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.onQuestDeleted(quest.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

class AddQuestDialog extends StatefulWidget {
  final Function(Quest) onQuestAdded;

  const AddQuestDialog({
    Key? key,
    required this.onQuestAdded,
  }) : super(key: key);

  @override
  State<AddQuestDialog> createState() => _AddQuestDialogState();
}

class _AddQuestDialogState extends State<AddQuestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Custom';
  int _experience = 10;
  int _skillPoints = 5;
  
  // Duration fields
  bool _isTimedQuest = false;
  int _days = 0;
  int _hours = 0;
  int _minutes = 0;

  // Time validation fields
  bool _enableTimeValidation = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final Map<DayOfWeek, bool> _selectedDays = {
    DayOfWeek.monday: false,
    DayOfWeek.tuesday: false,
    DayOfWeek.wednesday: false,
    DayOfWeek.thursday: false,
    DayOfWeek.friday: false,
    DayOfWeek.saturday: false,
    DayOfWeek.sunday: false,
  };

  final List<String> _categories = ['Custom', 'Mind', 'Body', 'Spirit'];

  @override
  void initState() {
    super.initState();
    // Default times
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 17, minute: 0);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitQuest() {
    if (_formKey.currentState!.validate()) {
      Duration? duration;
      if (_isTimedQuest) {
        duration = Duration(
          days: _days,
          hours: _hours,
          minutes: _minutes,
        );
      }

      TimeRange? validTimeRange;
      if (_enableTimeValidation && _startTime != null && _endTime != null) {
        validTimeRange = TimeRange(
          startTime: _startTime!,
          endTime: _endTime!,
        );
      }

      List<DayOfWeek>? validDays;
      if (_enableTimeValidation) {
        final selected = _selectedDays.entries
            .where((entry) => entry.value)
            .map((entry) => entry.key)
            .toList();
        if (selected.isNotEmpty) {
          validDays = selected;
        }
      }

      final newQuest = Quest(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        title: _titleController.text,
        description: _descriptionController.text,
        category: _selectedCategory,
        experience: _experience,
        skillPoints: _skillPoints,
        isDaily: false,
        isCompleted: false,
        completedAt: null,
        lastResetDate: null,
        duration: duration,
        isTimed: _isTimedQuest,
        validTimeRange: validTimeRange,
        validDays: validDays,
      );

      widget.onQuestAdded(newQuest);
      Navigator.pop(context);
    }
  }

  String _getDurationText() {
    if (!_isTimedQuest) return 'Not timed';
    
    final parts = <String>[];
    if (_days > 0) parts.add('$_days day${_days > 1 ? 's' : ''}');
    if (_hours > 0) parts.add('$_hours hour${_hours > 1 ? 's' : ''}');
    if (_minutes > 0) parts.add('$_minutes minute${_minutes > 1 ? 's' : ''}');
    
    if (parts.isEmpty) return '0 minutes';
    return parts.join(', ');
  }

  Future<void> _selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 17, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple[900]!.withOpacity(0.95),
              Colors.blue[900]!.withOpacity(0.95),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withOpacity(0.5),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add Custom Quest',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Quest Title',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a quest title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Quest Description',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a quest description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  style: const TextStyle(color: Colors.white),
                  dropdownColor: Colors.purple[900],
                  decoration: InputDecoration(
                    labelText: 'Category',
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.purple),
                    ),
                    filled: true,
                    fillColor: Colors.black.withOpacity(0.3),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Time Validation Toggle
                Row(
                  children: [
                    Switch(
                      value: _enableTimeValidation,
                      onChanged: (value) {
                        setState(() {
                          _enableTimeValidation = value;
                        });
                      },
                      activeThumbColor: Colors.purple[300],
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Enable Time Restrictions',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                // Time Range Selector (only shown if time validation is enabled)
                if (_enableTimeValidation) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Available Time Range:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Start Time:',
                              style: TextStyle(color: Colors.white70),
                            ),
                            ElevatedButton(
                              onPressed: _selectStartTime,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text(
                                _startTime?.format(context) ?? 'Select Start Time',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'End Time:',
                              style: TextStyle(color: Colors.white70),
                            ),
                            ElevatedButton(
                              onPressed: _selectEndTime,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple[800],
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 50),
                              ),
                              child: Text(
                                _endTime?.format(context) ?? 'Select End Time',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Days of Week Selector
                  const Text(
                    'Available Days:',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: DayOfWeek.values.map((day) {
                      return FilterChip(
                        label: Text(day.name),
                        selected: _selectedDays[day]!,
                        onSelected: (selected) {
                          setState(() {
                            _selectedDays[day] = selected;
                          });
                        },
                        selectedColor: Colors.purple[700],
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(
                          color: _selectedDays[day]! ? Colors.white : Colors.white70,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Timed Quest Toggle
                Row(
                  children: [
                    Switch(
                      value: _isTimedQuest,
                      onChanged: (value) {
                        setState(() {
                          _isTimedQuest = value;
                        });
                      },
                      activeThumbColor: Colors.purple[300],
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Timed Quest',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),

                // Duration Selector (only shown if timed quest is enabled)
                if (_isTimedQuest) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Duration: ${_getDurationText()}',
                    style: TextStyle(
                      color: Colors.blue[200],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Days
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Days: $_days',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Slider(
                              value: _days.toDouble(),
                              min: 0,
                              max: 30,
                              divisions: 30,
                              label: '$_days days',
                              activeColor: Colors.purple[300],
                              inactiveColor: Colors.purple[800],
                              onChanged: (value) {
                                setState(() {
                                  _days = value.round();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Hours
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hours: $_hours',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Slider(
                              value: _hours.toDouble(),
                              min: 0,
                              max: 23,
                              divisions: 23,
                              label: '$_hours hours',
                              activeColor: Colors.blue[300],
                              inactiveColor: Colors.blue[800],
                              onChanged: (value) {
                                setState(() {
                                  _hours = value.round();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Minutes
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Minutes: $_minutes',
                              style: const TextStyle(color: Colors.white),
                            ),
                            Slider(
                              value: _minutes.toDouble(),
                              min: 0,
                              max: 59,
                              divisions: 59,
                              label: '$_minutes minutes',
                              activeColor: Colors.green[300],
                              inactiveColor: Colors.green[800],
                              onChanged: (value) {
                                setState(() {
                                  _minutes = value.round();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Experience Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Experience Reward: $_experience',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Slider(
                      value: _experience.toDouble(),
                      min: 1,
                      max: 100,
                      divisions: 99,
                      label: '$_experience EXP',
                      activeColor: Colors.purple[300],
                      inactiveColor: Colors.purple[800],
                      onChanged: (value) {
                        setState(() {
                          _experience = value.round();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Skill Points Slider
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skill Points Reward: $_skillPoints',
                      style: const TextStyle(color: Colors.white),
                    ),
                    Slider(
                      value: _skillPoints.toDouble(),
                      min: 0,
                      max: 20,
                      divisions: 20,
                      label: '$_skillPoints SP',
                      activeColor: Colors.blue[300],
                      inactiveColor: Colors.blue[800],
                      onChanged: (value) {
                        setState(() {
                          _skillPoints = value.round();
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red[900]!.withOpacity(0.5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitQuest,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple[700],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Add Quest'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}