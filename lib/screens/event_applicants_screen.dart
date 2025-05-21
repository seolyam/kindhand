import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../services/application_service.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class EventApplicantsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventApplicantsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventApplicantsScreen> createState() => _EventApplicantsScreenState();
}

class _EventApplicantsScreenState extends State<EventApplicantsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _volunteers = [];
  List<Map<String, dynamic>> _interested = [];
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchApplicants();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      setState(() {});
    }
  }

  Future<void> _fetchApplicants() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventId = int.parse(widget.event['id'].toString());

      // Fetch volunteers
      final volunteers = await ApplicationService.getEventApplications(
        eventId: eventId,
        type: 'volunteer',
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      // Fetch interested
      final interested = await ApplicationService.getEventApplications(
        eventId: eventId,
        type: 'interested',
        status: _selectedFilter == 'all' ? null : _selectedFilter,
      );

      if (mounted) {
        setState(() {
          _volunteers = volunteers;
          _interested = interested;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching applicants: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateApplicationStatus(
      int applicationId, String status) async {
    try {
      final result = await ApplicationService.updateApplicationStatus(
        applicationId: applicationId,
        status: status,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Application ${status.toUpperCase()}')),
        );
        _fetchApplicants(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Failed to update status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Applicants for ${widget.event['title'] ?? 'Event'}',
          style: const TextStyle(fontSize: 18),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: 'Volunteers (${_volunteers.length})',
            ),
            Tab(
              text: 'Interested (${_interested.length})',
            ),
          ],
          labelColor: const Color(0xFF75B798),
          indicatorColor: const Color(0xFF75B798),
        ),
      ),
      body: Column(
        children: [
          // Filter options
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Filter by status:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedFilter = newValue;
                        });
                        _fetchApplicants();
                      }
                    },
                    items: <String>['all', 'pending', 'approved', 'rejected']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value == 'all'
                              ? 'All'
                              : value.substring(0, 1).toUpperCase() +
                                  value.substring(1),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
          // Tab content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF75B798),
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      // Volunteers tab
                      _buildApplicantsList(_volunteers),
                      // Interested tab
                      _buildApplicantsList(_interested),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplicantsList(List<Map<String, dynamic>> applicants) {
    if (applicants.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No applicants found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_selectedFilter != 'all') ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = 'all';
                  });
                  _fetchApplicants();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF75B798),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Show All Applicants'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchApplicants,
      color: const Color(0xFF75B798),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: applicants.length,
        itemBuilder: (context, index) {
          final applicant = applicants[index];
          return _buildApplicantCard(applicant);
        },
      ),
    );
  }

  Widget _buildApplicantCard(Map<String, dynamic> applicant) {
    final String fullName =
        "${applicant['first_name'] ?? ''} ${applicant['last_name'] ?? ''}"
            .trim();
    final String status = applicant['status'] ?? 'pending';
    final DateTime createdAt = DateTime.parse(applicant['created_at']);
    final String formattedDate = DateFormat('MMM d, yyyy').format(createdAt);

    // Parse skills if available
    List<String> skills = [];
    if (applicant['skills'] != null &&
        applicant['skills'].toString().isNotEmpty) {
      try {
        final skillsJson = applicant['skills'] as String;
        skills = List<String>.from(
            skillsJson.startsWith('[') ? jsonDecode(skillsJson) : []);
      } catch (e) {
        if (kDebugMode) {
          print('Error parsing skills: $e');
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF75B798),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: Text(
                      fullName.isNotEmpty
                          ? fullName.substring(0, 1).toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty ? fullName : 'Unknown User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        applicant['email'] ?? 'No email provided',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.substring(0, 1).toUpperCase() + status.substring(1),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (applicant['location'] != null &&
                applicant['location'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Color(0xFF75B798),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    applicant['location'],
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
            if (skills.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Skills:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: skills
                    .map((skill) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            skill,
                            style: const TextStyle(
                              color: Color(0xFF75B798),
                              fontSize: 12,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
            if (applicant['bio'] != null &&
                applicant['bio'].toString().isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Bio:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                applicant['bio'],
                style: TextStyle(
                  color: Colors.grey[800],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Applied on: $formattedDate',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                if (status == 'pending') ...[
                  Row(
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _updateApplicationStatus(
                          int.parse(applicant['id'].toString()),
                          'approved',
                        ),
                        tooltip: 'Approve',
                        iconSize: 28,
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _updateApplicationStatus(
                          int.parse(applicant['id'].toString()),
                          'rejected',
                        ),
                        tooltip: 'Reject',
                        iconSize: 28,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.orange;
    }
  }
}
