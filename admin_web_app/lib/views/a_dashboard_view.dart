import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:reorderables/reorderables.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../providers/a_login_provider.dart';
import '../providers/a_dashboard_provider.dart';
import 'dart:async';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  bool _isEditMode = false;
  Timer? _timer;

  final Map<String, dynamic> _emptyStats = {
    'metrics': {
      'avg_delivery_time_mins': 0,
      'on_time_percentage': 0,
      'total_finished_orders': 0,
      'total_ratings': 0,
      'avg_rating': 0.0,
      'total_orders_all_time': 0, 
      'in_progress_count': 0,     
      'pending_count': 0,         
      'total_late': 0,
      'working_drivers': 0,
      'today': {
        'avg_delivery': 0,
        'on_time': 0,
        'new_orders': 0,          
        'avg_rating': 0.0
      }
    },
    'rating_distribution': {},
    'weekly_volume': []
  };

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData(loadLayout: true);
    });

    int intervalSeconds = int.tryParse(dotenv.env['DASHBOARD_UPDATE_INTERVAL'] ?? '60') ?? 60;
    
    _timer = Timer.periodic(Duration(seconds: intervalSeconds), (timer) {
      if (mounted && !_isEditMode) { 
        // auto refresh data only
        _fetchData(loadLayout: false);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchData({bool loadLayout = false}) {
    final loginProv = Provider.of<LoginProvider>(context, listen: false);
    final dashProvider = Provider.of<DashboardProvider>(context, listen: false);
    
    if (loginProv.token != null) {
      // always update data
      dashProvider.fetchStats(loginProv.token!);
      
      // update layout if needed
      if (loadLayout) {
        dashProvider.loadPreferences(loginProv.token!); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashProvider = Provider.of<DashboardProvider>(context);
    final stats = dashProvider.stats ?? _emptyStats;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Operational Dashboard'),
        actions: [
          IconButton(
            icon: Icon(_isEditMode ? Icons.check_circle : Icons.edit),
            color: _isEditMode ? Colors.green : null,
            tooltip: _isEditMode ? 'Save Layout' : 'Customize Dashboard',
            onPressed: () => setState(() => _isEditMode = !_isEditMode),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.refresh),
            // refresh data only
            onPressed: () => _fetchData(loadLayout: false),
          ),
        ],
      ),
      body: dashProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                   if (dashProvider.stats == null)
                     _buildWarningBanner(dashProvider.error),
                   
                   _buildResponsiveGrid(dashProvider, stats),
                ],
              ),
            ),
    );
  }

  Widget _buildWarningBanner(String? error) {
     return Container(
       padding: const EdgeInsets.all(12),
       margin: const EdgeInsets.only(bottom: 16),
       decoration: BoxDecoration(
          color: Colors.amber.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.amber.shade300)
       ),
       width: double.infinity,
       child: Column(
         children: [
           Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
             Icon(Icons.warning_amber_rounded, color: Colors.brown, size: 24),
             SizedBox(width: 8),
             Text("No Live Data Available", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
           ]),
           if (error != null) Text(error, style: TextStyle(color: Colors.red.shade900, fontSize: 12)),
         ],
       ),
     );
  }

  Widget _buildResponsiveGrid(DashboardProvider provider, Map<String, dynamic> stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double screenWidth = constraints.maxWidth;
        int columns = screenWidth > 1000 ? 4 : (screenWidth > 600 ? 2 : 1);
        double blockWidth = (screenWidth - (columns - 1) * 16) / columns;

        List<Widget> gridItems = provider.widgetOrder.map((id) {
           return _buildWidgetById(id, provider, stats, blockWidth, columns);
        }).toList();

        if (_isEditMode) {
          return ReorderableWrap(
            spacing: 16,
            runSpacing: 16,
            needsLongPressDraggable: false,
            padding: EdgeInsets.zero,
            onReorder: (oldIndex, newIndex) {
              final token = Provider.of<LoginProvider>(context, listen: false).token;
              if (token != null) {
                provider.reorderWidgets(oldIndex, newIndex, token);
              }
            },
            children: gridItems,
          );
        }

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: gridItems,
        );
      },
    );
  }

  Widget _buildWidgetById(String id, DashboardProvider provider, Map<String, dynamic> stats, double blockWidth, int columns) {
    Widget content;
    final metrics = stats['metrics'] != null 
        ? Map<String, dynamic>.from(stats['metrics']) 
        : <String, dynamic>{}; 
    
    switch (id) {
      case 'kpi_cards':
        content = _buildBlockWrapper(
          id: id, title: 'Key Metrics (All Time)',
          width: blockWidth * columns + (columns - 1) * 16, 
          visible: provider.visibleWidgets.contains(id),
          provider: provider,
          child: _buildKpiRow(metrics, blockWidth, columns), 
        );
        break;

      case 'kpi_today':
        content = _buildBlockWrapper(
          id: id, title: 'Key Metrics (Today)',
          width: blockWidth * columns + (columns - 1) * 16, 
          visible: provider.visibleWidgets.contains(id),
          provider: provider,
          child: _buildKpiTodayRow(metrics['today'] ?? {}, blockWidth, columns), 
        );
        break;
        
      case 'total_orders':
        content = _buildBlockWrapper(
          id: id, title: 'Finished Orders',
          width: blockWidth,
          visible: provider.visibleWidgets.contains(id),
          provider: provider,
          child: _buildSimpleStatCard(
             "${metrics['total_finished_orders'] ?? 0}", 
             Icons.check_circle_outline, 
             Colors.blue
          ),
        );
        break;

      case 'total_ratings':
        content = _buildBlockWrapper(
          id: id, title: 'Total Num. of Ratings',
          width: blockWidth,
          visible: provider.visibleWidgets.contains(id),
          provider: provider,
          child: _buildSimpleStatCard(
             "${metrics['total_ratings'] ?? 0}", 
             Icons.reviews, 
             Colors.purple
          ),
        );
        break;

      case 'total_late': 
        content = _buildBlockWrapper(
          id: id, title: 'Total Num. of Late',
          width: blockWidth,
          visible: provider.visibleWidgets.contains(id),
          provider: provider,
          child: _buildSimpleStatCard(
             "${metrics['total_late'] ?? 0}", 
             Icons.warning_amber, 
             Colors.redAccent
          ),
        );
        break;

      case 'working_drivers': 
        content = _buildBlockWrapper(
          id: id, title: 'Working Drivers',
          width: blockWidth,
          visible: provider.visibleWidgets.contains(id),
          provider: provider,
          child: _buildSimpleStatCard(
             "${metrics['working_drivers'] ?? 0}", 
             Icons.badge, 
             Colors.teal
          ),
        );
        break;

        case 'in_progress_orders':
        content = _buildBlockWrapper(
          id: id, title: 'In-Progress Orders',
          width: blockWidth,
          visible: provider.visibleWidgets.contains(id),
          provider: provider,
          child: _buildSimpleStatCard(
             "${metrics['in_progress_count'] ?? 0}", 
             Icons.local_shipping, 
             Colors.orange
          ),
        );
        break;

      case 'pending_orders':
        content = _buildBlockWrapper(
          id: id, title: 'Pending Orders',
          width: blockWidth,
          visible: provider.visibleWidgets.contains(id),
          provider: provider,
          child: _buildSimpleStatCard(
             "${metrics['pending_count'] ?? 0}", 
             Icons.pending_actions, 
             Colors.grey
          ),
        );
        break;

      case 'volume_chart':
        content = _buildBlockWrapper(
          id: id, title: 'Order Volume (7 Days)',
          width: columns > 2 ? blockWidth * 2 + 16 : blockWidth * columns + (columns - 1) * 16,
          height: 300,
          visible: provider.visibleWidgets.contains(id),
          provider: provider,
          child: _buildVolumeChart(stats['weekly_volume']),
        );
        break;
      case 'rating_pie':
        content = _buildBlockWrapper(
          id: id, title: 'Driver Quality',
          width: columns > 2 ? blockWidth * 2 + 16 : blockWidth * columns + (columns - 1) * 16,
          height: 300,
          visible: provider.visibleWidgets.contains(id),
          provider: provider,
          child: _buildRatingPie(stats['rating_distribution'] != null 
              ? Map<String, dynamic>.from(stats['rating_distribution']) 
              : <String, dynamic>{}), 
        );
        break;
      default:
        content = const SizedBox.shrink();
    }

    return Container(
      key: ValueKey(id),
      child: content,
    );
  }

  Widget _buildBlockWrapper({
    required String id,
    required String title,
    required double width,
    double? height,
    required Widget child,
    required bool visible,
    required DashboardProvider provider,
  }) {
    if (!_isEditMode && !visible) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: _isEditMode 
          ? Border.all(color: visible ? Colors.blue : Colors.grey.withOpacity(0.3), width: 2) 
          : null,
        boxShadow: visible ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))] : [],
      ),
      child: Stack(
        children: [
          Opacity(
            opacity: (_isEditMode && !visible) ? 0.3 : 1.0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 16),
                  if (height != null) Expanded(child: child) else child,
                ],
              ),
            ),
          ),
          
          if (_isEditMode)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: const BorderRadius.only(topRight: Radius.circular(10), bottomLeft: Radius.circular(10)),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(right: 8.0),
                      child: Icon(Icons.drag_indicator, size: 20, color: Colors.blue),
                    ),
                    Checkbox(
                      value: visible,
                      activeColor: Colors.blue,
                      onChanged: (val) {
                         final token = Provider.of<LoginProvider>(context, listen: false).token;
                         if (token != null) provider.toggleWidget(id, val!, token);
                      },
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildKpiRow(Map<String, dynamic> metrics, double blockWidth, int columns) {
    final avg = metrics['avg_delivery_time_mins'] ?? 0;
    final onTime = metrics['on_time_percentage'] ?? 0;
    final totalOrders = metrics['total_orders_all_time'] ?? 0;
    final avgRating = metrics['avg_rating'] ?? 0.0;

    final List<Widget> cards = [
      _buildKpiCard("Avg Delivery", "$avg min", Icons.timer, Colors.orange),
      _buildKpiCard("On-Time", "$onTime%", Icons.check_circle, Colors.green),
      _buildKpiCard("Total Orders", "$totalOrders", Icons.list_alt, Colors.indigo), 
      _buildKpiCard("Avg Rating", "$avgRating★", Icons.stars, Colors.amber), 
    ];

    return Wrap(
      spacing: 16, runSpacing: 16,
      children: cards.map((c) => SizedBox(width: columns >= 4 ? (blockWidth - 12) : (blockWidth * columns / 2 - 12), child: c)).toList(),
    );
  }

  Widget _buildKpiTodayRow(Map<String, dynamic> todayMetrics, double blockWidth, int columns) {
    final avg = todayMetrics['avg_delivery'] ?? 0;
    final onTime = todayMetrics['on_time'] ?? 0;
    final newOrders = todayMetrics['new_orders'] ?? 0;
    final avgRating = todayMetrics['avg_rating'] ?? 0.0;

    final List<Widget> cards = [
      _buildKpiCard("Avg Delivery (Today)", "$avg min", Icons.timer_outlined, Colors.orange.shade700),
      _buildKpiCard("On-Time (Today)", "$onTime%", Icons.check_circle_outline, Colors.green.shade700),
      _buildKpiCard("New Orders (Today)", "$newOrders", Icons.new_releases, Colors.blueAccent.shade700), 
      _buildKpiCard("Avg Rating (Today)", "$avgRating★", Icons.star_half, Colors.amber.shade800), 
    ];

    return Wrap(
      spacing: 16, runSpacing: 16,
      children: cards.map((c) => SizedBox(width: columns >= 4 ? (blockWidth - 12) : (blockWidth * columns / 2 - 12), child: c)).toList(),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(title, style: TextStyle(fontSize: 14, color: color.withOpacity(0.8))),
      ]),
    );
  }

  Widget _buildSimpleStatCard(String value, IconData icon, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 40),
          const SizedBox(height: 16),
          Text(value, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildVolumeChart(List<dynamic>? volumeData) {
    if (volumeData == null || volumeData.isEmpty) {
      return const Center(child: Text("No data", style: TextStyle(color: Colors.grey)));
    }

    List<FlSpot> spots = [];
    double maxY = 0; 

    for (int i = 0; i < volumeData.length; i++) {
      double val = (volumeData[i]['count'] ?? 0).toDouble();
      if (val > maxY) maxY = val;
      spots.add(FlSpot(i.toDouble(), val));
    }

    double targetMaxY = maxY == 0 ? 5 : (maxY * 1.2);

    return LineChart(LineChartData(
      minY: 0,
      maxY: targetMaxY, 
      
      gridData: FlGridData(
        show: true, 
        drawVerticalLine: false,
        horizontalInterval: 1, 
      ),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1, 
            getTitlesWidget: (val, meta) {
              if (val % 1 == 0) {
                return Text(val.toInt().toString(), style: const TextStyle(fontSize: 10));
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        bottomTitles: AxisTitles(sideTitles: SideTitles(
          showTitles: true,
          interval: 1,
          getTitlesWidget: (val, meta) {
            int index = val.toInt();
            if (index >= 0 && index < volumeData.length) {
              String dateStr = volumeData[index]['date'].toString();
              return Padding(
                padding: const EdgeInsets.only(top: 8), 
                child: Text(
                  dateStr.length > 5 ? dateStr.substring(5) : dateStr, 
                  style: const TextStyle(fontSize: 10)
                )
              );
            }
            return const Text('');
          }
        )),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.shade200)),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          preventCurveOverShooting: true, 
          color: Colors.blue,
          barWidth: 4,
          isStrokeCapRound: true,
          dotData: FlDotData(show: true),
          belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
        )
      ],
    ));
  }

  Widget _buildRatingPie(Map<String, dynamic>? distribution) {
    if (distribution == null || distribution.isEmpty) return const Center(child: Text("No ratings yet", style: TextStyle(color: Colors.grey)));
    List<PieChartSectionData> sections = [];
    final colors = [Colors.red, Colors.orange, Colors.yellow, Colors.lightGreen, Colors.green];
    distribution.forEach((key, val) {
      final int stars = int.tryParse(key) ?? 0;
      final int count = val;
      if (count > 0 && stars >= 1 && stars <= 5) {
        sections.add(PieChartSectionData(color: colors[stars - 1], value: count.toDouble(), title: '$stars★', radius: 60, titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)));
      }
    });
    return Row(children: [
      Expanded(child: PieChart(PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2))),
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [5,4,3,2,1].map((stars) => Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Row(children: [Container(width: 12, height: 12, color: colors[stars-1]), const SizedBox(width: 8), Text('$stars Stars (${distribution[stars.toString()] ?? 0})')]))).toList())
    ]);
  }
}