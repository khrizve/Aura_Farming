import 'dart:async';
import 'package:aura_farming/data/inventory_data.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'screens/home_screen.dart';
import 'screens/quest_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/more_screen.dart';
import 'models/quest.dart';
import 'models/skill.dart';
import 'models/aura_level.dart';
import 'models/inventory_item.dart';
import 'models/streak.dart';
import 'data/quest_data.dart';
import 'data/skill_data.dart';
import 'utils/theme_data.dart';
import 'services/storage_service.dart';

class AuraFarmingApp extends StatefulWidget {
  const AuraFarmingApp({Key? key}) : super(key: key);

  @override
  State<AuraFarmingApp> createState() => _AuraFarmingAppState();
}

class _AuraFarmingAppState extends State<AuraFarmingApp> {
  int _currentIndex = 0;
  late AuraLevel _auraLevel;
  late List<Skill> _skills;
  late List<Quest> _quests;
  late List<InventoryItem> _inventory;
  late Streak _streak;
  int _availableSkillPoints = 0;
  bool _isLoading = true;
  Map<DateTime, int> _dailyCompletion = {};
  Timer? _questTimer;

  final StorageService _storageService = StorageService();

  @override
  void initState() {
    super.initState();
    _loadAppData();
  }

  @override
  void dispose() {
    _questTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAppData() async {
    setState(() {
      _isLoading = true;
    });

    // Load all data from storage
    final savedAuraLevel = await _storageService.loadAuraLevel();
    final savedSkills = await _storageService.loadSkills();
    final savedQuests = await _storageService.loadQuests();
    final savedInventory = await _storageService.loadInventory();
    final savedSkillPoints = await _storageService.loadSkillPoints();
    final savedDailyCompletion = await _storageService.loadDailyCompletion();
    final lastResetCheck = await _storageService.loadLastResetCheck();
    final savedStreak = await _storageService.loadStreak();

    setState(() {
      _auraLevel = savedAuraLevel ?? AuraLevel(
        level: 1,
        experience: 0,
        requiredExperience: 100,
        characterImage: 'assets/images/characters/level_1.png',
      );
      
      _skills = savedSkills.isNotEmpty ? savedSkills : SkillData.getInitialSkills();
      
      // Initialize quests and check for daily reset
      final initialQuests = savedQuests.isNotEmpty ? savedQuests : [
        ...QuestData.getDailyQuests(),
        ...QuestData.getWeeklyQuests(),
      ];
      
      _quests = _checkAndResetDailyQuests(initialQuests, lastResetCheck);
      
      _inventory = savedInventory;
      _availableSkillPoints = savedSkillPoints;
      _dailyCompletion = savedDailyCompletion;
      _streak = savedStreak;
      _isLoading = false;
    });

    // Save the current time as last reset check
    await _storageService.saveLastResetCheck(DateTime.now());
    await _saveAllData();

    // Start timer for updating timed quests
    _startQuestTimer();
  }

  void _startQuestTimer() {
    _questTimer?.cancel();
    _questTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimedQuests();
    });
  }

  void _updateTimedQuests() {
    bool needsUpdate = false;
    
    setState(() {
      for (int i = 0; i < _quests.length; i++) {
        final quest = _quests[i];
        if (quest.isTimed && quest.startTime != null && !quest.isCompleted) {
          final now = DateTime.now();
          final elapsed = now.difference(quest.startTime!);
          _quests[i] = quest.updateElapsedTime(elapsed);
          needsUpdate = true;
        }
      }
    });

    if (needsUpdate) {
      _saveAllData();
    }
  }

  List<Quest> _checkAndResetDailyQuests(List<Quest> quests, DateTime? lastResetCheck) {
    final now = DateTime.now();
    
    // If we've never checked before or it's a new day, reset daily quests
    if (lastResetCheck == null || !_isSameDay(lastResetCheck, now)) {
      return QuestData.resetDailyQuests(quests);
    }
    
    return quests;
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  Future<void> _saveAllData() async {
    await _storageService.saveAuraLevel(_auraLevel);
    await _storageService.saveSkills(_skills);
    await _storageService.saveQuests(_quests);
    await _storageService.saveInventory(_inventory);
    await _storageService.saveSkillPoints(_availableSkillPoints);
    await _storageService.saveDailyCompletion(_dailyCompletion);
    await _storageService.saveStreak(_streak);
  }

  void _completeQuest(Quest quest) async {
    if (quest.isCompleted) return;

    // Check if quest is valid based on time constraints
    if (!quest.isValidNow && !quest.isTimedQuestCompleted()) {
      // Show error message or notification
      return;
    }

    setState(() {
      // Mark quest as completed
      final index = _quests.indexWhere((q) => q.id == quest.id);
      if (index != -1) {
        _quests[index] = quest.copyWith(
          isCompleted: true,
          completedAt: DateTime.now(),
        );
      }

      // Add experience to aura level
      _auraLevel = _auraLevel.addExperience(quest.experience);

      // Add skill points
      _availableSkillPoints += quest.skillPoints;

      // Update daily completion tracking
      _updateDailyCompletion();

      // Update streak
      _updateStreak();

      // Check for new inventory items
      _checkForNewInventoryItems();
    });

    // Save data after changes
    await _saveAllData();
  }

  // NEW METHOD: Handle starting timed quest
  void _startTimedQuest(String questId) async {
    final quest = _quests.firstWhere((q) => q.id == questId);
    
    // Check if quest is valid based on time constraints
    if (!quest.isValidNow) {
      // Show error message or notification
      return;
    }

    setState(() {
      final index = _quests.indexWhere((q) => q.id == questId);
      if (index != -1) {
        _quests[index] = _quests[index].startTimedQuest();
      }
    });

    // Save data after changes
    await _saveAllData();
  }

  // NEW METHOD: Handle adding custom quest
  void _addCustomQuest(Quest quest) async {
    setState(() {
      _quests.add(quest);
    });

    // Save data after changes
    await _saveAllData();
  }

  // NEW METHOD: Handle deleting custom quest
  void _deleteCustomQuest(String questId) async {
    setState(() {
      _quests.removeWhere((quest) => quest.id == questId);
    });

    // Save data after changes
    await _saveAllData();
  }

  // NEW METHOD: Handle skill level up
  void _levelUpSkill(Skill skill) async {
    if (_availableSkillPoints <= 0) return;

    setState(() {
      // Use one skill point
      _availableSkillPoints -= 1;
      
      // Find and update the skill
      final index = _skills.indexWhere((s) => s.id == skill.id);
      if (index != -1) {
        _skills[index] = skill.useSkillPoint();
      }
    });

    // Save data after changes
    await _saveAllData();
  }

  void _updateDailyCompletion() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    // Count completed daily quests for today
    final completedToday = _quests
        .where((quest) => quest.isDaily && 
            quest.isCompleted && 
            quest.completedAt != null &&
            isSameDay(quest.completedAt!, today))
        .length;

    _dailyCompletion[normalizedToday] = completedToday;
  }

  void _updateStreak() {
    final today = DateTime.now();
    final normalizedToday = DateTime(today.year, today.month, today.day);
    
    // Only update streak if today hasn't been completed yet
    if (!_streak.completionHistory.containsKey(normalizedToday) || 
        !_streak.completionHistory[normalizedToday]!) {
      setState(() {
        _streak = _streak.markTodayCompleted();
      });
    }
  }

  void _checkForNewInventoryItems() {
    // Add inventory items based on achievements
    final now = DateTime.now();
    
    // Add aura card every 3 levels
    if (_auraLevel.level % 3 == 0) {
      final newItem = InventoryItem(
        id: 'aura_card_${_auraLevel.level}_earned',
        name: 'Aura Level ${_auraLevel.level} Card',
        description: 'Achieved by reaching Aura Level ${_auraLevel.level}',
        imagePath: 'assets/images/cards/level_${_auraLevel.level}.png',
        auraLevelRequired: _auraLevel.level,
        acquiredDate: now,
        rarity: _getRarityForLevel(_auraLevel.level),
        category: ItemCategory.auraCard,
        stats: {'auraBoost': _auraLevel.level * 10, 'achievement': _auraLevel.level * 5},
      );

      _addInventoryItem(newItem);
    }

    // Add fantasy weapon every 5 levels
    if (_auraLevel.level % 5 == 0) {
      final newItem = InventoryItem(
        id: 'weapon_${_auraLevel.level}_earned',
        name: 'Level ${_auraLevel.level} Weapon',
        description: 'A powerful weapon earned at level ${_auraLevel.level}',
        imagePath: 'assets/images/weapons/level_${_auraLevel.level}.jpg',
        auraLevelRequired: _auraLevel.level,
        acquiredDate: now,
        rarity: _getRarityForLevel(_auraLevel.level),
        category: ItemCategory.fantasyWeapon,
        stats: {'attack': _auraLevel.level * 15, 'strength': _auraLevel.level * 8},
      );

      _addInventoryItem(newItem);
    }

    // Add magical pet every 7 levels
    if (_auraLevel.level % 7 == 0) {
      final newItem = InventoryItem(
        id: 'pet_${_auraLevel.level}_earned',
        name: 'Level ${_auraLevel.level} Pet',
        description: 'A magical companion earned at level ${_auraLevel.level}',
        imagePath: 'assets/images/pets/level_${_auraLevel.level}.jpg',
        auraLevelRequired: _auraLevel.level,
        acquiredDate: now,
        rarity: _getRarityForLevel(_auraLevel.level),
        category: ItemCategory.magicalPet,
        stats: {'companionship': _auraLevel.level * 12, 'magic': _auraLevel.level * 10},
      );

      _addInventoryItem(newItem);
    }

    // Add dark shadow every 10 levels
    if (_auraLevel.level % 10 == 0) {
      final newItem = InventoryItem(
        id: 'shadow_${_auraLevel.level}_earned',
        name: 'Level ${_auraLevel.level} Shadow',
        description: 'A dark shadow entity earned at level ${_auraLevel.level}',
        imagePath: 'assets/images/shadows/level_${_auraLevel.level}.jpg',
        auraLevelRequired: _auraLevel.level,
        acquiredDate: now,
        rarity: _getRarityForLevel(_auraLevel.level),
        category: ItemCategory.darkShadow,
        stats: {'darkness': _auraLevel.level * 20, 'mystery': _auraLevel.level * 15},
      );

      _addInventoryItem(newItem);
    }

    // Check for streak achievements
    if (_streak.currentStreak == 7) {
      final streakItem = InventoryData.getSpecialEventItems()
          .firstWhere((item) => item.id == 'special_daily_streak_7');
      _addInventoryItem(streakItem.copyWith(acquiredDate: now));
    }

    if (_streak.currentStreak == 30) {
      final streakItem = InventoryData.getSpecialEventItems()
          .firstWhere((item) => item.id == 'special_daily_streak_30');
      _addInventoryItem(streakItem.copyWith(acquiredDate: now));
    }

    // Check for all skills at level 5
    if (_skills.every((skill) => skill.level >= 5)) {
      final skillItem = InventoryData.getSpecialEventItems()
          .firstWhere((item) => item.id == 'special_all_skills_5');
      _addInventoryItem(skillItem.copyWith(acquiredDate: now));
    }
  }

  void _addInventoryItem(InventoryItem newItem) {
    // Check if item already exists
    if (!_inventory.any((item) => item.id == newItem.id)) {
      setState(() {
        _inventory.add(newItem);
      });
    }
  }

  Rarity _getRarityForLevel(int level) {
    if (level >= 15) return Rarity.mythical;
    if (level >= 10) return Rarity.legendary;
    if (level >= 7) return Rarity.epic;
    if (level >= 4) return Rarity.rare;
    return Rarity.common;
  }

  void _onDateSelected(DateTime date) {
    // Handle date selection for daily quests
    print('Selected date: $date');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFF0A0A0A),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                ),
                const SizedBox(height: 20),
                Text(
                  'Loading Aura...',
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      title: 'Aura Farming',
      theme: AppTheme.darkTheme,
      home: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            HomeScreen(
              auraLevel: _auraLevel,
              skills: _skills,
              availableSkillPoints: _availableSkillPoints,
              onDateSelected: _onDateSelected,
              dailyCompletion: _dailyCompletion,
              streak: _streak,
              onSkillLevelUp: _levelUpSkill,
            ),
            QuestScreen(
              quests: _quests,
              onQuestComplete: _completeQuest,
              onQuestStarted: _startTimedQuest,
              onQuestAdded: _addCustomQuest,
              onQuestDeleted: _deleteCustomQuest,
            ),
            InventoryScreen(
              inventoryItems: _inventory,
              currentAuraLevel: _auraLevel.level,
            ),
            const MoreScreen(),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            gradient: AppTheme.magicalGradient,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            selectedItemColor: Colors.white,
            unselectedItemColor: Colors.white70,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Quests',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.inventory),
                label: 'Inventory',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.more_horiz),
                label: 'More',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const AuraFarmingApp());
}