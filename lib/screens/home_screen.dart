import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../provider/news_provider.dart';
import '../theme/app_colors.dart';
import '../models/article_model.dart';
import '../widgets/shimmer_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  int _currentNavIndex = 0;
  String _selectedBlogCategory = 'All';
  final Set<String> _bookmarkedBlogTitles = {};

  final List<Map<String, dynamic>> _mockBlogs = [
    {
      'article': Article(
        title: 'The Future of AI: Trends to Watch in 2025',
        description: 'From generative models to AI agents, explore the key trends shaping the future of artificial intelligence.',
        urlToImage: 'https://images.unsplash.com/photo-1677442136019-21780efad99a?auto=format&fit=crop&w=600&q=80',
        url: 'https://www.theguardian.com/technology/2025/ai-trends',
        sourceName: 'The Guardian',
        publishedAt: '2025-06-28T00:00:00Z',
        sectionName: 'Technology',
        content: 'From generative models to AI agents, explore the key trends shaping the future of artificial intelligence. AI agents are set to become more autonomous, handling complex workflows across various fields...',
      ),
      'readTime': '6 min read',
      'timeAgo': '8h ago',
      'category': 'Technology',
    },
    {
      'article': Article(
        title: 'Global Climate Summit 2025: Key Outcomes',
        description: 'Leaders from around the world meet to discuss actionable steps toward a sustainable future.',
        urlToImage: 'https://images.unsplash.com/photo-1466611653911-95081537e5b7?auto=format&fit=crop&w=600&q=80',
        url: 'https://www.theguardian.com/world/2025/climate-summit',
        sourceName: 'The Guardian',
        publishedAt: '2025-06-28T00:00:00Z',
        sectionName: 'World',
        content: 'Leaders from around the world meet to discuss actionable steps toward a sustainable future. Key topics included green energy transitions, carbon tax enforcement, and funding for developing nations...',
      ),
      'readTime': '5 min read',
      'timeAgo': '12h ago',
      'category': 'World',
    },
    {
      'article': Article(
        title: 'Markets Rally as Inflation Shows Signs of Cooling',
        description: 'Global markets see a surge as inflation data brings relief to investors and policymakers.',
        urlToImage: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?auto=format&fit=crop&w=600&q=80',
        url: 'https://www.theguardian.com/business/2025/markets-rally',
        sourceName: 'The Guardian',
        publishedAt: '2025-06-28T00:00:00Z',
        sectionName: 'Business',
        content: 'Global markets see a surge as inflation data brings relief to investors and policymakers. Major stock indices climbed as the latest CPI reports indicated a steady decline in consumer prices...',
      ),
      'readTime': '4 min read',
      'timeAgo': '1d ago',
      'category': 'Business',
    },
    {
      'article': Article(
        title: 'New Breakthrough in Heart Disease Treatment',
        description: 'Researchers discover a new therapy that could revolutionize heart disease treatment.',
        urlToImage: 'https://images.unsplash.com/photo-1628595308571-98329ef5b2a6?auto=format&fit=crop&w=600&q=80',
        url: 'https://www.theguardian.com/lifeandstyle/2025/heart-disease-treatment',
        sourceName: 'The Guardian',
        publishedAt: '2025-06-28T00:00:00Z',
        sectionName: 'Health',
        content: 'Researchers discover a new therapy that could revolutionize heart disease treatment. The novel gene-editing technique targets specific genetic markers responsible for arterial plaque buildup...',
      ),
      'readTime': '7 min read',
      'timeAgo': '1d ago',
      'category': 'Health',
    },
    {
      'article': Article(
        title: 'Space Tourism Takes Off: A New Era Begins',
        description: 'Private companies are making space travel more accessible, opening up new possibilities for exploration.',
        urlToImage: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?auto=format&fit=crop&w=600&q=80',
        url: 'https://www.theguardian.com/technology/2025/space-tourism',
        sourceName: 'The Guardian',
        publishedAt: '2025-06-28T00:00:00Z',
        sectionName: 'Technology',
        content: 'Private companies are making space travel more accessible, opening up new possibilities for exploration. Rocket launches are happening weekly now, carrying civilians into low Earth orbit for tourism...',
      ),
      'readTime': '8 min read',
      'timeAgo': '2d ago',
      'category': 'Technology',
    },
  ];

  // Mock data matching the reference image precisely
  final List<Map<String, dynamic>> _gridCategories = [
    {
      'name': 'World',
      'icon': Icons.public_rounded,
      'color': AppColors.catWorld,
      'id': 'general',
    },
    {
      'name': 'India',
      'icon': Icons.museum_rounded,
      'color': AppColors.catIndia,
      'id': 'india_search', // will trigger a custom search for 'India'
    },
    {
      'name': 'Tech',
      'icon': Icons.memory_rounded,
      'color': AppColors.catTech,
      'id': 'technology',
    },
    {
      'name': 'Business',
      'icon': Icons.trending_up_rounded,
      'color': AppColors.catBusiness,
      'id': 'business',
    },
    {
      'name': 'Sports',
      'icon': Icons.sports_soccer_rounded,
      'color': AppColors.catSports,
      'id': 'sports',
    },
    {
      'name': 'Entertainment',
      'icon': Icons.movie_rounded,
      'color': AppColors.catEntertainment,
      'id': 'entertainment',
    },
    {
      'name': 'Science',
      'icon': Icons.science_rounded,
      'color': AppColors.catScience,
      'id': 'science',
    },
    {
      'name': 'Health',
      'icon': Icons.favorite_rounded,
      'color': AppColors.catHealth,
      'id': 'health',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchSubmit(String query) {
    if (query.trim().isNotEmpty) {
      context.read<NewsProvider>().search(query);
    }
    _searchFocusNode.unfocus();
  }

  void _onCategoryTap(Map<String, dynamic> cat, NewsProvider provider) {
    _searchController.clear();
    if (cat['id'] == 'india_search') {
      provider.search('India');
    } else {
      provider.setCategory(cat['id']);
    }
  }

  void _resetHomeView(NewsProvider provider) {
    setState(() {
      _currentNavIndex = 0;
      _searchController.clear();
    });
    provider.clearSearch();
    provider.setCategory('general');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NewsProvider>();

    Widget bodyContent;
    if (_currentNavIndex == 0) {
      bodyContent = RefreshIndicator(
        onRefresh: () async {
          if (provider.isSearchActive) {
            await provider.search(provider.searchQuery);
          } else {
            await provider.loadHeadlines();
          }
        },
        color: AppColors.highlight,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // Dynamic Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: _buildHeader(),
              ),
            ),

            // Explore Categories Section (Now Live)
            SliverToBoxAdapter(
              child: _buildExploreCategoriesSection(provider),
            ),

            // Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        provider.isSearchActive
                            ? 'Search Results: "${provider.searchQuery}"'
                            : '${provider.selectedCategory[0].toUpperCase()}${provider.selectedCategory.substring(1)} News',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (provider.isSearchActive || provider.selectedCategory != 'general')
                      TextButton.icon(
                        onPressed: () => _resetHomeView(provider),
                        icon: const Icon(Icons.close, size: 16, color: AppColors.highlight),
                        label: const Text(
                          'Reset',
                          style: TextStyle(color: AppColors.highlight, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Live feed
            _buildLiveResults(provider),
            const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for floating bottom nav
          ],
        ),
      );
    } else if (_currentNavIndex == 1) {
      bodyContent = _buildBlogsTab();
    } else {
      bodyContent = _buildSettingsTab();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: Stack(
        children: [
          // 1. Ambient Glow Backdrops
          _buildBackgroundGlows(),

          // 2. Main content container
          SafeArea(
            bottom: false,
            child: bodyContent,
          ),

          // 3. Floating Bottom Navigation Bar
          _buildBottomNavBar(context, provider),
        ],
      ),
    );
  }

  // Background Glows mapping the premium aesthetics
  Widget _buildBackgroundGlows() {
    return Stack(
      children: [
        Container(
          color: const Color(0xFF070514),
        ),
        // Glow 1: Top-Right Blue
        Positioned(
          top: -150,
          right: -150,
          width: 450,
          height: 450,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1E88E5).withOpacity(0.18),
                  const Color(0xFF22D3EE).withOpacity(0.06),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Glow 2: Mid-Left Purple
        Positioned(
          top: 250,
          left: -200,
          width: 500,
          height: 500,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF7C3AED).withOpacity(0.15),
                  const Color(0xFF8B5CF6).withOpacity(0.04),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Glow 3: Bottom-Right Pink Accent
        Positioned(
          bottom: -150,
          right: -100,
          width: 400,
          height: 400,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFFD946EF).withOpacity(0.1),
                  const Color(0xFFF472B6).withOpacity(0.02),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),
        // Blur Backdrop overlay
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 75, sigmaY: 75),
            child: Container(
              color: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  // Header UI matching reference design
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text.rich(
                TextSpan(
                  text: 'Good Evening, ',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  children: [
                    TextSpan(
                      text: 'Alex',
                      style: TextStyle(
                        color: Color(0xFFA78BFA),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(text: ' 👋'),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Stay curious.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                  height: 1.1,
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Stay ',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.8,
                      height: 1.1,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [
                        Color(0xFF3B82F6), // Blue
                        Color(0xFF8B5CF6), // Royal Purple
                        Color(0xFFEC4899), // Pink
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ).createShader(bounds),
                    child: const Text(
                      'informed.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 1.2,
            ),
            color: Colors.white.withOpacity(0.03),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              _searchFocusNode.requestFocus();
            },
            icon: const Icon(
              Icons.search,
              color: Colors.white,
              size: 24,
            ),
          ),
        ),
      ],
    );
  }

  // Search input field with capsule layout
  Widget _buildSearchBar() {
    return _buildGlassContainer(
      borderRadius: 30,
      backgroundColor: Colors.white.withOpacity(0.04),
      borderColor: Colors.white.withOpacity(0.08),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          const Icon(
            Icons.search_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmit,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w400,
              ),
              decoration: const InputDecoration(
                hintText: 'Search news, topics or publishers...',
                hintStyle: TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Filter settings button
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (context) => const FilterBottomSheet(),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Color(0xFFE2E8F0),
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Source Badge builder for mockup cards
  Widget _buildSourceBadge(String source) {
    Widget logoWidget;
    if (source == 'Reuters') {
      logoWidget = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.center,
        child: const Text(
          'R',
          style: TextStyle(
            color: Colors.black,
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      );
    } else if (source == 'ESPNcricinfo') {
      logoWidget = Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Color(0xFF00A3E0),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          'E',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (source == 'TechCrunch') {
      logoWidget = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: const Color(0xFF00B500),
          borderRadius: BorderRadius.circular(2),
        ),
        alignment: Alignment.center,
        child: const Text(
          'tc',
          style: TextStyle(
            color: Colors.white,
            fontSize: 7,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else if (source == 'The Guardian') {
      logoWidget = Container(
        width: 14,
        height: 14,
        decoration: const BoxDecoration(
          color: Color(0xFF0A3060),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Text(
          'G',
          style: TextStyle(
            color: Colors.white,
            fontSize: 8,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    } else {
      logoWidget = Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.newspaper, size: 8, color: Colors.white),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        logoWidget,
        const SizedBox(width: 6),
        Text(
          source,
          style: const TextStyle(
            color: Color(0xFFC7CDD8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // BREAKING NOW horizontal scroller


  // EXPLORE CATEGORIES horizontal scrolling scroller
  Widget _buildExploreCategoriesSection(NewsProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'EXPLORE CATEGORIES',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.8,
                ),
              ),
              Row(
                children: [
                  Text(
                    'View all',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 95,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _gridCategories.length,
              itemBuilder: (context, index) {
                final cat = _gridCategories[index];
                final Color catColor = cat['color'];
                final String catId = cat['id'] as String;
                final bool isSelected = (!provider.isSearchActive && provider.selectedCategory == catId) ||
                    (catId == 'india_search' && provider.isSearchActive && provider.searchQuery == 'India');
                return Padding(
                  padding: const EdgeInsets.only(right: 14.0),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _onCategoryTap(cat, provider),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            color: isSelected ? catColor.withOpacity(0.18) : catColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? catColor : catColor.withOpacity(0.35),
                              width: isSelected ? 2.0 : 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected ? catColor.withOpacity(0.15) : catColor.withOpacity(0.08),
                                blurRadius: isSelected ? 12 : 10,
                                spreadRadius: isSelected ? 2 : 1,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            cat['icon'],
                            color: catColor,
                            size: 26,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat['name'],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // POPULAR TOPICS hashtag layout
  Widget _buildPopularTopicsSection(NewsProvider provider) {
    final List<Map<String, dynamic>> topics = [
      {'name': '# AI ↗', 'color': const Color(0xFF22D3EE), 'query': 'AI'},
      {'name': '# Stocks', 'color': const Color(0xFF10B981), 'query': 'stocks'},
      {'name': '# Climate', 'color': const Color(0xFF0D9488), 'query': 'climate'},
      {'name': '# Elections', 'color': const Color(0xFF8B5CF6), 'query': 'elections'},
      {'name': '# Crypto', 'color': const Color(0xFFF59E0B), 'query': 'crypto'},
      {'name': '# Space', 'color': const Color(0xFF3B82F6), 'query': 'space'},
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 0.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'POPULAR TOPICS',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: topics.map((topic) {
              final Color color = topic['color'];
              final String query = topic['query'];
              final isSelected = provider.isSearchActive && provider.searchQuery.toLowerCase() == query.toLowerCase();
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _searchController.text = query;
                  });
                  provider.search(query);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withOpacity(0.15) : color.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.25),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  child: Text(
                    topic['name'],
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // --- BLOGS TAB ---
  Widget _buildBlogsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Stack(
        children: [
          // Background Globe Backdrop
          Positioned(
            top: -40,
            right: -60,
            width: 320,
            height: 320,
            child: Opacity(
              opacity: 0.35,
              child: Image.asset(
                'assets/Globe.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBlogsHeader(),
              const SizedBox(height: 12),
              _buildCategoryTabs(),
              const SizedBox(height: 20),
              _buildBlogsList(),
              const SizedBox(height: 120), // Bottom padding for spacing above the floating navbar
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlogsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Blogs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'In-depth stories and analysis',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
               shape: BoxShape.circle,
               border: Border.all(
                 color: Colors.white.withOpacity(0.12),
                 width: 1.2,
               ),
               color: Colors.white.withOpacity(0.02),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.search,
                color: Colors.white,
                size: 22,
              ),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final List<Map<String, dynamic>> categories = [
      {
        'id': 'All',
        'name': 'All Blogs',
        'icon': Icons.format_list_bulleted_rounded,
      },
      {
        'id': 'Technology',
        'name': 'Technology',
        'icon': Icons.laptop_chromebook_rounded,
      },
      {
        'id': 'Business',
        'name': 'Business',
        'icon': Icons.business_center_rounded,
      },
      {
        'id': 'World',
        'name': 'World',
        'icon': Icons.public_rounded,
      },
      {
        'id': 'Health',
        'name': 'Health',
        'icon': Icons.favorite_rounded,
      },
    ];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final categoryId = cat['id'] as String;
          final isSelected = _selectedBlogCategory == categoryId;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedBlogCategory = categoryId;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isSelected 
                    ? const Color(0xFF8B5CF6)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected 
                      ? const Color(0xFF8B5CF6)
                      : Colors.white.withOpacity(0.08),
                  width: 1.2,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withOpacity(0.25),
                    blurRadius: 10,
                    spreadRadius: -1,
                  ),
                ] : null,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    cat['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    cat['name'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.6),
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlogsList() {
    final filteredBlogs = _selectedBlogCategory == 'All'
        ? _mockBlogs
        : _mockBlogs.where((blog) => blog['category'] == _selectedBlogCategory).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: filteredBlogs.map((blog) {
          final isBookmarked = _bookmarkedBlogTitles.contains(blog['article'].title);
          final Article article = blog['article'] as Article;
          final category = blog['category'] as String;
          final readTime = blog['readTime'] as String;
          final timeAgo = blog['timeAgo'] as String;
          
          Color badgeTextColor;
          Color badgeBgColor;
          
          if (category == 'Technology') {
            badgeTextColor = const Color(0xFFA78BFA);
            badgeBgColor = const Color(0xFF8B5CF6).withOpacity(0.15);
          } else if (category == 'World') {
            badgeTextColor = const Color(0xFF34D399);
            badgeBgColor = const Color(0xFF10B981).withOpacity(0.15);
          } else if (category == 'Business') {
            badgeTextColor = const Color(0xFFFBBF24);
            badgeBgColor = const Color(0xFFF59E0B).withOpacity(0.15);
          } else { // Health
            badgeTextColor = const Color(0xFFFCA5A5);
            badgeBgColor = const Color(0xFFEF4444).withOpacity(0.15);
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1.2,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => DetailScreen(article: article),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: CachedNetworkImage(
                        imageUrl: article.urlToImage ?? '',
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 110,
                          height: 110,
                          color: Colors.white.withOpacity(0.02),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 110,
                          height: 110,
                          color: Colors.white.withOpacity(0.02),
                          child: const Icon(Icons.broken_image_rounded, color: Colors.white24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeBgColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              category,
                              style: TextStyle(
                                color: badgeTextColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Title
                          Text(
                            article.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // Description
                          Text(
                            article.description ?? '',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          // Footer Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '$timeAgo  •  $readTime',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (isBookmarked) {
                                      _bookmarkedBlogTitles.remove(article.title);
                                    } else {
                                      _bookmarkedBlogTitles.add(article.title);
                                    }
                                  });
                                },
                                child: Icon(
                                  isBookmarked
                                      ? Icons.bookmark_rounded
                                      : Icons.bookmark_border_rounded,
                                  color: isBookmarked
                                      ? const Color(0xFF8B5CF6)
                                      : Colors.white.withOpacity(0.4),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // About tab code removed.

  // --- SETTINGS TAB ---
  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsHeader(),
          const SizedBox(height: 12),
          _buildSettingsHeroCard(),
          const SizedBox(height: 24),
          _buildSettingsAppearance(),
          const SizedBox(height: 24),
          _buildSettingsContentData(),
          const SizedBox(height: 24),
          _buildSettingsPreferences(),
          const SizedBox(height: 24),
          _buildSettingsAboutLegal(),
          const SizedBox(height: 120), // Bottom padding for spacing above the floating navbar
        ],
      ),
    );
  }

  Widget _buildSettingsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Settings',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Customize your experience',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsHeroCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.2,
          ),
          color: Colors.white.withOpacity(0.02),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18.8),
          child: Stack(
            children: [
              Positioned(
                right: -40,
                top: -30,
                bottom: -30,
                width: 200,
                child: Opacity(
                  opacity: 0.15,
                  child: CachedNetworkImage(
                    imageUrl: 'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?auto=format&fit=crop&w=300&q=80',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Row(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(
                          Icons.settings_suggest_rounded,
                          color: const Color(0xFF8B5CF6).withOpacity(0.2),
                          size: 64,
                        ),
                        Icon(
                          Icons.settings_rounded,
                          color: const Color(0xFF8B5CF6).withOpacity(0.4),
                          size: 48,
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    Transform.rotate(
                      angle: 0.15,
                      child: Container(
                        width: 52,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF8B5CF6),
                              Color(0xFFC084FC),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withOpacity(0.4),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'N',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFF3B82F6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        border: Border.all(
                          color: const Color(0xFFC084FC).withOpacity(0.4),
                          width: 1.2,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          'N',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Newstler',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Version 1.0.0 (Build 1)',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFF8B5CF6).withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFFA78BFA),
                                size: 10,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "You're on the latest version",
                                style: TextStyle(
                                  color: Color(0xFFA78BFA),
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsAppearance() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSectionTitle('Appearance'),
          const SizedBox(height: 10),
          _buildGlassContainer(
            borderRadius: 20,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildRadioTile(
                  icon: Icons.wb_sunny_rounded,
                  iconColor: const Color(0xFFA78BFA),
                  title: 'Light Mode',
                  subtitle: 'Clean and bright',
                  isSelected: false,
                ),
                _buildSettingsDivider(),
                _buildRadioTile(
                  icon: Icons.nights_stay_rounded,
                  iconColor: const Color(0xFFA78BFA),
                  title: 'Dark Mode',
                  subtitle: 'Easy on the eyes',
                  isSelected: true,
                ),
                _buildSettingsDivider(),
                _buildRadioTile(
                  icon: Icons.desktop_windows_rounded,
                  iconColor: const Color(0xFFA78BFA),
                  title: 'System Default',
                  subtitle: 'Use device theme',
                  isSelected: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsContentData() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSectionTitle('Content & Data'),
          const SizedBox(height: 10),
          _buildGlassContainer(
            borderRadius: 20,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.download_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'Data Saver',
                  subtitle: 'Use less data while browsing',
                ),
                _buildSettingsDivider(),
                _buildActionTile(
                  icon: Icons.bookmark_outline_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Read Later',
                  subtitle: 'View and manage saved articles',
                ),
                _buildSettingsDivider(),
                _buildActionTile(
                  icon: Icons.access_time_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Clear Cache',
                  subtitle: 'Free up storage space',
                  badgeText: '48.7 MB',
                ),
                _buildSettingsDivider(),
                _buildActionTile(
                  icon: Icons.cloud_download_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Offline Mode',
                  subtitle: 'Download articles to read offline',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPreferences() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSectionTitle('Preferences'),
          const SizedBox(height: 10),
          _buildGlassContainer(
            borderRadius: 20,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.text_fields_rounded,
                  iconColor: const Color(0xFFEC4899),
                  title: 'Text Size',
                  subtitle: 'Adjust the size of text',
                  badgeText: 'Medium',
                ),
                _buildSettingsDivider(),
                _buildActionTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF06B6D4),
                  title: 'Language',
                  subtitle: 'Choose your preferred language',
                  badgeText: 'English',
                ),
                _buildSettingsDivider(),
                _buildActionTile(
                  icon: Icons.notifications_none_rounded,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Push Notifications',
                  subtitle: 'Stay updated with breaking news',
                  trailingWidget: SizedBox(
                    width: 38,
                    height: 22,
                    child: Switch(
                      value: true,
                      onChanged: (val) {},
                      activeColor: Colors.white,
                      activeTrackColor: const Color(0xFF8B5CF6),
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.white.withOpacity(0.12),
                    ),
                  ),
                ),
                _buildSettingsDivider(),
                _buildActionTile(
                  icon: Icons.tune_rounded,
                  iconColor: const Color(0xFF10B981),
                  title: 'News Preferences',
                  subtitle: 'Choose topics you care about',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsAboutLegal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSettingsSectionTitle('About & Legal'),
          const SizedBox(height: 10),
          _buildGlassContainer(
            borderRadius: 20,
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _buildActionTile(
                  icon: Icons.info_outline_rounded,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'About Newstler',
                  subtitle: 'Learn more about the app',
                ),
                _buildSettingsDivider(),
                _buildActionTile(
                  icon: Icons.verified_user_outlined,
                  iconColor: const Color(0xFF10B981),
                  title: 'Privacy Policy',
                  subtitle: 'How we protect your data',
                ),
                _buildSettingsDivider(),
                _buildActionTile(
                  icon: Icons.article_outlined,
                  iconColor: const Color(0xFFF59E0B),
                  title: 'Terms of Use',
                  subtitle: 'Read our terms and conditions',
                ),
                _buildSettingsDivider(),
                _buildActionTile(
                  icon: Icons.badge_outlined,
                  iconColor: const Color(0xFF8B5CF6),
                  title: 'Open Source Licenses',
                  subtitle: 'License details for open source software',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withOpacity(0.04),
      indent: 52,
      endIndent: 16,
    );
  }

  Widget _buildRadioTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: iconColor.withOpacity(0.08),
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            height: 18,
            width: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? const Color(0xFF8B5CF6) : Colors.white.withOpacity(0.18),
                width: 1.5,
              ),
              color: isSelected ? const Color(0xFF8B5CF6).withOpacity(0.12) : Colors.transparent,
            ),
            child: isSelected
                ? const Center(
                    child: Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFFA78BFA),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badgeText,
    Widget? trailingWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: iconColor.withOpacity(0.08),
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (badgeText != null) ...[
            Text(
              badgeText,
              style: const TextStyle(
                color: Color(0xFFA78BFA),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
          ],
          trailingWidget ?? const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF64748B),
            size: 18,
          ),
        ],
      ),
    );
  }

  // Floating bottom navigation bar matching the design perfectly
  Widget _buildBottomNavBar(BuildContext context, NewsProvider provider) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1.2,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.home_rounded, "Home", active: _currentNavIndex == 0, provider: provider),
                  _buildNavItem(1, Icons.rate_review_outlined, "Blogs", active: _currentNavIndex == 1, provider: provider),
                  _buildNavItem(2, Icons.settings_rounded, "Settings", active: _currentNavIndex == 2, provider: provider),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {required bool active, required NewsProvider provider}) {
    final Color activeColor = const Color(0xFF8B5CF6); // Royal Purple accent matching the image
    final Color inactiveColor = const Color(0xFF64748B);

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentNavIndex = index;
          if (index == 0) {
            _resetHomeView(provider);
          }
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: active ? activeColor : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            if (active) ...[
              // Glowing line indicator
              Container(
                width: 12,
                height: 2.5,
                decoration: BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: activeColor.withOpacity(0.8),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                color: active ? Colors.white : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Live query results widget
  Widget _buildLiveResults(NewsProvider provider) {
    switch (provider.status) {
      case NewsStatus.loading:
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: ShimmerCard(),
            ),
            childCount: 4,
          ),
        );

      case NewsStatus.error:
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Unable to load news',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  provider.errorMessage,
                  style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (provider.isSearchActive) {
                      provider.search(provider.searchQuery);
                    } else {
                      provider.loadHeadlines();
                    }
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.06),
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.12)),
                  ),
                ),
              ],
            ),
          ),
        );

      case NewsStatus.success:
      case NewsStatus.idle:
        if (provider.articles.isEmpty) {
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text(
                  'No articles found.',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final article = provider.articles[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: GlassArticleCard(
                    article: article,
                    onTap: () {
                      print('[TRACE STAGE 5 - Before Navigating to DetailScreen]');
                      print('  article.title: ${article.title}');
                      print('  article.description.length: ${article.description?.length ?? 0}');
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => DetailScreen(article: article),
                      );
                    },
                  ),
                );
              },
              childCount: provider.articles.length,
            ),
          ),
        );
    }
  }

  // Glass Container Utility
  Widget _buildGlassContainer({
    required Widget child,
    double borderRadius = 16,
    EdgeInsetsGeometry? padding,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.06),
              width: 1.2,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

// Custom Glassmorphic News Card for live API items
class GlassArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback onTap;

  const GlassArticleCard({
    super.key,
    required this.article,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.06),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // 1. Globe asset image positioned in the background on the right
          Positioned(
            right: -35,
            top: -20,
            bottom: -20,
            width: 195,
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Opacity(
                  opacity: 0.45,
                  child: Image.asset(
                    'assets/Globe.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // 2. InkWell for tapping
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Left Side: Image with Source Badge
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 130,
                          height: 122,
                          child: article.urlToImage != null && article.urlToImage!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: article.urlToImage!,
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: AppColors.surface,
                                    child: const Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryAccent),
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: AppColors.surface,
                                    child: const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        size: 24,
                                        color: AppColors.mutedText,
                                      ),
                                    ),
                                  ),
                                )
                              : Container(
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: AppColors.primaryGradient,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.newspaper_rounded,
                                      size: 32,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      
                      // Source tag overlaid on image top-left
                      if (article.sourceName != null && article.sourceName!.isNotEmpty)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4F46E5), // Indigo blue color matching the Hindu badge
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              article.sourceName!,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // Right Side: Article metadata and action
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          article.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (article.description != null && article.description!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            article.description!,
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 11,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const Spacer(), // Replaces spacing/spaceBetween dynamically to prevent bottom overflow
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              article.publishedAt != null ? _formatDate(article.publishedAt!) : '',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.04),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                  width: 1.0,
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }
}


