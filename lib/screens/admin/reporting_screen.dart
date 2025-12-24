import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../db/db_helper.dart';
import '../../providers/auth_provider.dart';

class ReportingScreen extends StatefulWidget {
  const ReportingScreen({super.key});

  @override
  State<ReportingScreen> createState() => _ReportingScreenState();
}

class _ReportingScreenState extends State<ReportingScreen> {
  String _selectedPeriod = 'daily';
  DateTime _selectedDate = DateTime.now();
  Map<String, int> _kpis = {};
  double _revenue = 0.0;
  List<Map<String, dynamic>> _dailyCounts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _loading = true);
    try {
      DateTime start, end;
      switch (_selectedPeriod) {
        case 'daily':
          start = DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          );
          end = start.add(const Duration(days: 1));
          break;
        case 'weekly':
          start = _selectedDate.subtract(
            Duration(days: _selectedDate.weekday - 1),
          );
          end = start.add(const Duration(days: 7));
          break;
        case 'monthly':
          start = DateTime(_selectedDate.year, _selectedDate.month, 1);
          end = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          break;
        default:
          start = _selectedDate;
          end = _selectedDate.add(const Duration(days: 1));
      }

      final kpis = await DBHelper.instance.getAppointmentKpis(
        start: start,
        end: end,
      );
      final revenue = await DBHelper.instance.getRevenueByDateRange(start, end);
      final dailyCounts = await DBHelper.instance.getDailyAppointmentCounts(
        start: start,
        end: end,
      );

      setState(() {
        _kpis = kpis;
        _revenue = revenue;
        _dailyCounts = dailyCounts;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading reports: $e')));
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _loadReports();
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is admin
    if (auth.user?.role.toLowerCase() != 'admin') {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You do not have permission to access this page.'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporting & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDate,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Period selector
                  Row(
                    children: [
                      const Text(
                        'Period: ',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _selectedPeriod,
                        items: const [
                          DropdownMenuItem(
                            value: 'daily',
                            child: Text('Daily'),
                          ),
                          DropdownMenuItem(
                            value: 'weekly',
                            child: Text('Weekly'),
                          ),
                          DropdownMenuItem(
                            value: 'monthly',
                            child: Text('Monthly'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedPeriod = value);
                            _loadReports();
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      Text(
                        DateFormat(
                          'MMM dd, yyyy',
                          Localizations.localeOf(context).languageCode,
                        ).format(_selectedDate),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // KPI Cards
                  const Text(
                    'Key Performance Indicators',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildKPICard(
                        'Total Appointments',
                        _kpis['total'] ?? 0,
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                      _buildKPICard(
                        'Completed',
                        _kpis['completed'] ?? 0,
                        Icons.check_circle,
                        Colors.green,
                      ),
                      _buildKPICard(
                        'Emergency Cases',
                        _kpis['emergency'] ?? 0,
                        Icons.warning,
                        Colors.red,
                      ),
                      _buildKPICard(
                        'Routine Cases',
                        _kpis['routine'] ?? 0,
                        Icons.healing,
                        Colors.orange,
                      ),
                      _buildKPICard(
                        'Canceled',
                        _kpis['canceled'] ?? 0,
                        Icons.cancel,
                        Colors.grey,
                      ),
                      _buildRevenueCard(
                        'Revenue',
                        _revenue,
                        Icons.attach_money,
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Emergency vs Routine Breakdown
                  const Text(
                    'Emergency vs Routine Cases',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildCaseTypeCard(
                                  'Emergency',
                                  _kpis['emergency'] ?? 0,
                                  Colors.red,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildCaseTypeCard(
                                  'Routine',
                                  _kpis['routine'] ?? 0,
                                  Colors.green,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if ((_kpis['emergency'] ?? 0) +
                                  (_kpis['routine'] ?? 0) >
                              0)
                            LinearProgressIndicator(
                              value:
                                  (_kpis['emergency'] ?? 0) /
                                  ((_kpis['emergency'] ?? 0) +
                                      (_kpis['routine'] ?? 0)),
                              backgroundColor: Colors.green.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.red,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daily Appointment Counts (for weekly/monthly view)
                  if (_selectedPeriod != 'daily' &&
                      _dailyCounts.isNotEmpty) ...[
                    const Text(
                      'Daily Breakdown',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: _dailyCounts.map((count) {
                            return ListTile(
                              title: Text(
                                DateFormat(
                                  'MMM dd, yyyy',
                                  Localizations.localeOf(context).languageCode,
                                ).format(DateTime.parse(count['day'])),
                              ),
                              trailing: Text('${count['count']} appointments'),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildKPICard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCard(
    String title,
    double value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              '\$${value.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCaseTypeCard(String type, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            type,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}







