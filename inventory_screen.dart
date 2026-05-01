import 'package:flutter/material.dart';
import '../models/inventory_item.dart';
import '../data/inventory_data.dart';
import '../widgets/inventory_card.dart';

class InventoryScreen extends StatefulWidget {
  final List<InventoryItem> inventoryItems;
  final int currentAuraLevel;

  const InventoryScreen({
    Key? key,
    required this.inventoryItems,
    required this.currentAuraLevel,
  }) : super(key: key);

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> with SingleTickerProviderStateMixin {
  late List<InventoryItem> _allInventoryItems;
  bool _showUnlockedOnly = false;
  late TabController _tabController;
  ItemCategory _selectedCategory = ItemCategory.auraCard;

  @override
  void initState() {
    super.initState();
    _updateInventoryItems();
    _tabController = TabController(
      length: ItemCategory.values.length,
      vsync: this,
    );
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _selectedCategory = ItemCategory.values[_tabController.index];
      });
    }
  }

  @override
  void didUpdateWidget(InventoryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentAuraLevel != widget.currentAuraLevel || 
        oldWidget.inventoryItems != widget.inventoryItems) {
      _updateInventoryItems();
    }
  }

  void _updateInventoryItems() {
    _allInventoryItems = InventoryData.getInventoryWithUnlockStatus(
      widget.currentAuraLevel,
      widget.inventoryItems,
    );
  }

  List<InventoryItem> get _displayedItems {
    var items = InventoryData.getItemsByCategory(
      _selectedCategory,
      widget.currentAuraLevel,
      widget.inventoryItems,
    );
    
    if (_showUnlockedOnly) {
      items = items.where((item) => item.isUnlocked).toList();
    }
    
    return items.toList();
  }

  int get _unlockedCount {
    return _allInventoryItems.where((item) => item.isUnlocked).length;
  }

  int get _totalCount {
    return _allInventoryItems.length;
  }

  int get _categoryUnlockedCount {
    return _allInventoryItems
        .where((item) => item.category == _selectedCategory && item.isUnlocked)
        .length;
  }

  int get _categoryTotalCount {
    return _allInventoryItems
        .where((item) => item.category == _selectedCategory)
        .length;
  }

  void _showCardDetail(InventoryItem item) {
    if (!item.isUnlocked) return;

    showDialog(
      context: context,
      builder: (context) => CardDetailDialog(item: item),
    );
  }

  void _showCategoryStats() {
    final stats = InventoryData.getCategoryStats(widget.inventoryItems);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Collection Stats',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ItemCategory.values.map((category) {
              final categoryStat = stats[category]!;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: category.color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(category.icon, color: category.color, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: categoryStat['percentage'] / 100,
                            backgroundColor: Colors.grey[800],
                            valueColor: AlwaysStoppedAnimation<Color>(category.color),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${categoryStat['unlocked']}/${categoryStat['total']} (${categoryStat['percentage']}%)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            'Rarest: ${categoryStat['rarestItem']}',
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              backgroundColor: Colors.purple[800],
              label: Text(
                '$_unlockedCount/$_totalCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(
              _showUnlockedOnly ? Icons.lock_open : Icons.filter_list,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _showUnlockedOnly = !_showUnlockedOnly;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics, color: Colors.white),
            onPressed: _showCategoryStats,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.black.withOpacity(0.5),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.purple,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              tabs: ItemCategory.values.map((category) {
                final unlockedCount = _allInventoryItems
                    .where((item) => item.category == category && item.isUnlocked)
                    .length;
                final totalCount = _allInventoryItems
                    .where((item) => item.category == category)
                    .length;
                
                return Tab(
                  icon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(category.displayName),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text('$unlockedCount/$totalCount'),
                        backgroundColor: unlockedCount == totalCount
                            ? Colors.green[800]
                            : Colors.grey[800],
                        labelStyle: const TextStyle(fontSize: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: ItemCategory.values.map((category) {
          return _buildCategoryView(category);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryView(ItemCategory category) {
    final items = InventoryData.getItemsByCategory(
      category,
      widget.currentAuraLevel,
      widget.inventoryItems,
    );
    
    final filteredItems = _showUnlockedOnly
        ? items.where((item) => item.isUnlocked).toList()
        : items.toList();

    if (filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: 64,
              color: category.color.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              _showUnlockedOnly 
                  ? 'No unlocked ${category.displayName.toLowerCase()}'
                  : 'No ${category.displayName.toLowerCase()} available',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _showUnlockedOnly 
                    ? 'Reach higher Aura Levels to unlock more ${category.displayName.toLowerCase()}!'
                    : 'Complete quests and level up to unlock ${category.displayName.toLowerCase()}!',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),
            if (!_showUnlockedOnly)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _showUnlockedOnly = true;
                  });
                },
                icon: const Icon(Icons.lock_open),
                label: const Text('Show Only Unlocked'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: category.color,
                ),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Category info and filter indicator
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          color: category.color.withOpacity(0.1),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(category.icon, size: 20, color: category.color),
                  const SizedBox(width: 8),
                  Text(
                    category.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(
                      '${filteredItems.where((item) => item.isUnlocked).length}/${filteredItems.length}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    backgroundColor: category.color.withOpacity(0.3),
                  ),
                ],
              ),
              if (_showUnlockedOnly)
                Chip(
                  label: const Text(
                    'UNLOCKED ONLY',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  backgroundColor: Colors.green[800],
                ),
            ],
          ),
        ),
        
        // Rarity filter chips
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: Rarity.values.map((rarity) {
                final rarityCount = filteredItems
                    .where((item) => item.rarity == rarity && (!_showUnlockedOnly || item.isUnlocked))
                    .length;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: rarity.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${rarity.shortName} ($rarityCount)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    selected: false,
                    onSelected: null,
                    backgroundColor: rarity.color.withOpacity(0.2),
                    shape: StadiumBorder(
                      side: BorderSide(color: rarity.color.withOpacity(0.5)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        
        // Inventory grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return InventoryGridCard(
                item: item,
                onTap: () => _showCardDetail(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CardDetailDialog extends StatefulWidget {
  final InventoryItem item;

  const CardDetailDialog({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<CardDetailDialog> createState() => _CardDetailDialogState();
}

class _CardDetailDialogState extends State<CardDetailDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<Color?> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    ));

    _glowAnimation = ColorTween(
      begin: Colors.transparent,
      end: widget.item.rarity.color.withOpacity(0.3),
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeInOut),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: _glowAnimation.value ?? Colors.transparent,
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: child,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.item.category.color.withOpacity(0.95),
                widget.item.rarity.color.withOpacity(0.95),
                Colors.purple[800]!.withOpacity(0.95),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: widget.item.rarity.color.withOpacity(0.5),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.item.category.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.item.category.icon, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      widget.item.category.displayName.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Card Image with magical border
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.item.rarity.color.withOpacity(0.8),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.item.rarity.color.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    widget.item.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              widget.item.rarity.color.withOpacity(0.6),
                              widget.item.rarity.color.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: Icon(
                          widget.item.category.icon,
                          size: 60,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Card Details
              Text(
                widget.item.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Fantasy',
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.item.rarity.color.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.item.rarity.displayName.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                widget.item.description,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Stats
              if (widget.item.stats.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stats:',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: widget.item.stats.entries.map((entry) {
                          return Chip(
                            label: Text(
                              '${entry.key}: ${entry.value}',
                              style: const TextStyle(fontSize: 11),
                            ),
                            backgroundColor: widget.item.rarity.color.withOpacity(0.3),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailItem(
                    Icons.star,
                    'Level ${widget.item.auraLevelRequired}',
                    Colors.yellow[700]!,
                  ),
                  _buildDetailItem(
                    Icons.calendar_today,
                    _formatDate(widget.item.acquiredDate),
                    Colors.blue[300]!,
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Close button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.item.category.color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}