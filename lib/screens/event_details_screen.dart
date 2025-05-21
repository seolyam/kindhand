import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/application_service.dart';
import 'package:flutter/foundation.dart';

class EventDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  bool _isLoading = true;
  bool _hasVolunteered = false;
  bool _isInterested = false;
  String? _volunteerStatus;
  String? _interestedStatus;
  bool _isSubmittingVolunteer = false;
  bool _isSubmittingInterested = false;

  @override
  void initState() {
    super.initState();
    _checkApplicationStatus();
  }

  Future<void> _checkApplicationStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final eventId = int.parse(widget.event['id'].toString());
      final result = await ApplicationService.checkApplicationStatus(eventId);

      setState(() {
        _hasVolunteered = result['has_volunteer_application'] ?? false;
        _isInterested = result['has_interested_application'] ?? false;
        _volunteerStatus = result['volunteer_status'];
        _interestedStatus = result['interested_status'];
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error checking application status: $e');
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _applyAsVolunteer() async {
    if (_isSubmittingVolunteer) return;

    setState(() {
      _isSubmittingVolunteer = true;
    });

    try {
      final eventId = int.parse(widget.event['id'].toString());
      final result = await ApplicationService.applyToEvent(
        eventId: eventId,
        applicationType: 'volunteer',
        withdraw: _hasVolunteered,
      );

      if (result['success']) {
        setState(() {
          _hasVolunteered = !_hasVolunteered;
          if (_hasVolunteered) {
            _volunteerStatus = 'pending';
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('You have volunteered for this event!')),
            );
          } else {
            _volunteerStatus = null;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('You have withdrawn your volunteer application')),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to apply')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmittingVolunteer = false;
      });
    }
  }

  Future<void> _markAsInterested() async {
    if (_isSubmittingInterested) return;

    setState(() {
      _isSubmittingInterested = true;
    });

    try {
      final eventId = int.parse(widget.event['id'].toString());
      final result = await ApplicationService.applyToEvent(
        eventId: eventId,
        applicationType: 'interested',
        withdraw: _isInterested,
      );

      if (result['success']) {
        setState(() {
          _isInterested = !_isInterested;
          if (_isInterested) {
            _interestedStatus = 'pending';
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('You have marked interest in this event!')),
            );
          } else {
            _interestedStatus = null;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                      Text('You have removed your interest in this event')),
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ?? 'Failed to mark interest')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isSubmittingInterested = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the screen height to calculate the modal height
    final screenHeight = MediaQuery.of(context).size.height;

    // Format dates if they exist
    String formattedDate = '';
    if (widget.event['event_date'] != null &&
        widget.event['event_date'].toString().isNotEmpty) {
      try {
        final DateTime eventDate =
            DateTime.parse(widget.event['event_date'].toString());
        formattedDate = DateFormat('MMMM d, yyyy').format(eventDate);
      } catch (e) {
        formattedDate = '';
      }
    }

    // Get creator name
    final String creatorName =
        widget.event['first_name'] != null && widget.event['last_name'] != null
            ? "${widget.event['first_name']} ${widget.event['last_name']}"
            : "Unknown Creator";

    return Container(
      height: screenHeight * 0.85, // Takes up 85% of screen height
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag indicator
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with event image/logo
                    Container(
                      width: double.infinity,
                      height: 180,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF75B798),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.event,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Event title with verification icon
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.event['title'] ?? 'Event Title',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF75B798),
                          size: 24,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Location with icon
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Color(0xFF75B798),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.event['location'] ??
                                'Location not specified',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Date with icon if available
                    if (formattedDate.isNotEmpty) ...[
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            color: Color(0xFF75B798),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Creator with icon
                    Row(
                      children: [
                        const Icon(
                          Icons.person,
                          color: Color(0xFF75B798),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Created by: $creatorName",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag('Online', const Color(0xFFD1E7DD)),
                        if (widget.event['is_remote'] == 1)
                          _buildTag('Remote', const Color(0xFFD1E7DD)),
                        _buildTag('Volunteering', const Color(0xFFD1E7DD)),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Application status indicators
                    if (_hasVolunteered || _isInterested) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE9ECEF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Application Status',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_hasVolunteered) ...[
                              Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(_volunteerStatus),
                                    color: _getStatusColor(_volunteerStatus),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Volunteer application: ${_formatStatus(_volunteerStatus)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_isInterested) ...[
                              Row(
                                children: [
                                  Icon(
                                    _getStatusIcon(_interestedStatus),
                                    color: _getStatusColor(_interestedStatus),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Interest: ${_formatStatus(_interestedStatus)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // About the event section
                    const Text(
                      'About the event',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Text(
                        widget.event['description'] ??
                            'No description provided',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // About the creator section
                    const Text(
                      'About the creator',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE9ECEF)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF75B798),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  creatorName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.event['location'] ??
                                      'Location not specified',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Created on: ${_formatCreatedDate(widget.event['created_at'])}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
          // Fixed bottom action buttons bar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _applyAsVolunteer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _hasVolunteered
                          ? Colors.red[400]
                          : const Color(0xFF75B798),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: _isSubmittingVolunteer
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _hasVolunteered ? 'Withdraw' : 'Volunteer',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _markAsInterested,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _isInterested
                          ? Colors.red[400]
                          : const Color(0xFF75B798),
                      side: BorderSide(
                        color: _isInterested
                            ? Colors.red[400]!
                            : const Color(0xFF75B798),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSubmittingInterested
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: _isInterested
                                  ? Colors.red[400]
                                  : const Color(0xFF75B798),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _isInterested ? 'Not Interested' : 'Interested',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF75B798),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _formatCreatedDate(dynamic createdAt) {
    if (createdAt == null) return 'Unknown date';

    try {
      final DateTime date = DateTime.parse(createdAt.toString());
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return 'Unknown date';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
      default:
        return Icons.hourglass_empty;
    }
  }

  Color _getStatusColor(String? status) {
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

  String _formatStatus(String? status) {
    if (status == null) return 'Unknown';

    // Capitalize first letter
    return status.substring(0, 1).toUpperCase() + status.substring(1);
  }
}
