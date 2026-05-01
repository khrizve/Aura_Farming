import 'package:flutter/material.dart';
import '../widgets/character_widget.dart';
import '../widgets/aura_level_widget.dart';
import '../widgets/streak_widget.dart';
import '../widgets/mini_calendar.dart';
import '../widgets/skills_section.dart';
import '../models/aura_level.dart';
import '../models/skill.dart';
import '../models/streak.dart';

class HomeScreen extends StatefulWidget {
  final AuraLevel auraLevel;
  final List<Skill> skills;
  final int availableSkillPoints;
  final Function(DateTime) onDateSelected;
  final Map<DateTime, int> dailyCompletion;
  final Streak streak;
  final Function(Skill)? onSkillLevelUp; // Add this

  const HomeScreen({
    Key? key,
    required this.auraLevel,
    required this.skills,
    required this.availableSkillPoints,
    required this.onDateSelected,
    required this.dailyCompletion,
    required this.streak,
    this.onSkillLevelUp, // Add this
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Character Display
            CharacterWidget(auraLevel: widget.auraLevel),
            const SizedBox(height: 24),
            
            // Aura Level Progress
            AuraLevelWidget(auraLevel: widget.auraLevel),
            const SizedBox(height: 16),
            
            // Streak Widget and Mini Calendar - Side by side with horizontal scrolling
            SizedBox(
              height: 320, // Fixed height to accommodate both widgets
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  // Streak Widget
                  Container(
                    width: MediaQuery.of(context).size.width - 32, // Full width minus padding
                    margin: const EdgeInsets.only(right: 16),
                    child: StreakWidget(streak: widget.streak),
                  ),
                  
                  // Mini Calendar
                  SizedBox(
                    width: MediaQuery.of(context).size.width - 32, // Full width minus padding
                    child: MiniCalendar(
                      selectedDay: _selectedDate,
                      onDaySelected: (day) {
                        setState(() {
                          _selectedDate = day;
                        });
                        widget.onDateSelected(day);
                      },
                      dailyCompletion: widget.dailyCompletion,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Skills Section
            SkillsSection(
              skills: widget.skills,
              availableSkillPoints: widget.availableSkillPoints,
              onLevelUp: widget.onSkillLevelUp, // Pass the callback
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}