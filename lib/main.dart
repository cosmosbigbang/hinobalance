import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const HinoBalanceApp());
}

class HinoBalanceApp extends StatelessWidget {
  const HinoBalanceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '하이노밸런스',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff667eea),
          brightness: Brightness.light,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String apiBaseUrl = 'https://jnext-backend.onrender.com'; // Render 서버
  
  Map<String, dynamic> draftStats = {};
  Map<String, dynamic> contentStats = {};
  Map<String, dynamic> rawStats = {};
  
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Draft 데이터
      final draftResponse = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/hino/review/draft/'),
      );
      
      // Content 데이터
      final contentResponse = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/hino/review/content/'),
      );
      
      // Raw 데이터
      final rawResponse = await http.get(
        Uri.parse('$apiBaseUrl/api/v1/hino/review/raw/'),
      );

      if (draftResponse.statusCode == 200 &&
          contentResponse.statusCode == 200 &&
          rawResponse.statusCode == 200) {
        
        final draftData = json.decode(utf8.decode(draftResponse.bodyBytes));
        final contentData = json.decode(utf8.decode(contentResponse.bodyBytes));
        final rawData = json.decode(utf8.decode(rawResponse.bodyBytes));

        setState(() {
          draftStats = _calculateStats(draftData['data'] ?? []);
          contentStats = _calculateStats(contentData['data'] ?? []);
          rawStats = _calculateStats(rawData['data'] ?? []);
          isLoading = false;
        });
      } else {
        throw Exception('서버 응답 오류');
      }
    } catch (e) {
      setState(() {
        errorMessage = '데이터 로드 실패: $e';
        isLoading = false;
      });
    }
  }

  Map<String, dynamic> _calculateStats(List<dynamic> data) {
    final stats = <String, int>{};
    final allTypes = [
      'theory_integrated',
      'category_theory',
      'exercise',
      'meme_scenario',
      'other',
    ];

    // 모든 타입 초기화
    for (var type in allTypes) {
      stats[type] = 0;
    }

    // 실제 데이터 카운트
    for (var item in data) {
      final type = item['content_type'] ?? 'other';
      stats[type] = (stats[type] ?? 0) + 1;
    }

    return {
      'stats': stats,
      'total': data.length,
      'data': data,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff667eea), Color(0xff764ba2)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text(
                      '하이노밸런스',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '데이터 관리 v1.0',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),

              // Tabs
              Container(
                color: Colors.white,
                child: TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xff667eea),
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color(0xff667eea),
                  tabs: const [
                    Tab(text: 'Draft'),
                    Tab(text: 'Content'),
                    Tab(text: 'Raw'),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  color: Colors.white,
                  child: isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : errorMessage != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(errorMessage!, textAlign: TextAlign.center),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _loadData,
                                    icon: const Icon(Icons.refresh),
                                    label: const Text('다시 시도'),
                                  ),
                                ],
                              ),
                            )
                          : TabBarView(
                              controller: _tabController,
                              children: [
                                _buildStatsView(draftStats, '초안'),
                                _buildStatsView(contentStats, '콘텐츠'),
                                _buildStatsView(rawStats, '원본'),
                              ],
                            ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        tooltip: '새로고침',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStatsView(Map<String, dynamic> statsData, String label) {
    final stats = statsData['stats'] as Map<String, int>? ?? {};
    final total = statsData['total'] as int? ?? 0;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label 데이터',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '총 $total개',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Divider(height: 32),
                  _buildStatItem('통합 이론', stats['theory_integrated'] ?? 0, Icons.book),
                  _buildStatItem('카테고리 이론', stats['category_theory'] ?? 0, Icons.category),
                  _buildStatItem('운동', stats['exercise'] ?? 0, Icons.fitness_center),
                  _buildStatItem('밈 시나리오', stats['meme_scenario'] ?? 0, Icons.emoji_emotions),
                  _buildStatItem('기타', stats['other'] ?? 0, Icons.more_horiz),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xff667eea)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff667eea).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xff667eea),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
