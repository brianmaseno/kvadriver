// lib/widgets/rating_popup.dart
import 'package:flutter/material.dart';
import '../data/services/api_service.dart';

class RatingPopup extends StatefulWidget {
  final int rideId;
  final String partnerName;
  final String? partnerImage;
  final bool isDriver; // true = driver rating customer
  final VoidCallback? onComplete;
  final VoidCallback? onSkip;

  const RatingPopup({
    super.key,
    required this.rideId,
    required this.partnerName,
    this.partnerImage,
    this.isDriver = true,
    this.onComplete,
    this.onSkip,
  });

  /// Show rating popup as a modal dialog
  static Future<bool?> show(
    BuildContext context, {
    required int rideId,
    required String partnerName,
    String? partnerImage,
    bool isDriver = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => RatingPopup(
        rideId: rideId,
        partnerName: partnerName,
        partnerImage: partnerImage,
        isDriver: isDriver,
        onComplete: () => Navigator.pop(context, true),
        onSkip: () => Navigator.pop(context, false),
      ),
    );
  }

  @override
  State<RatingPopup> createState() => _RatingPopupState();
}

class _RatingPopupState extends State<RatingPopup>
    with SingleTickerProviderStateMixin {
  int _rating = 0;
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  // Rating categories for customers (from driver's perspective)
  final List<String> _categories = [
    'Polite',
    'Respectful',
    'On Time',
    'Clear Directions',
    'Pleasant',
    'Good Tipper',
  ];
  final Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await ApiService.submitRating(
        rideId: widget.rideId,
        rating: _rating,
        feedback: _feedbackController.text.trim().isEmpty
            ? null
            : _feedbackController.text.trim(),
        categories: _selectedCategories.toList(),
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thank you for your feedback!'),
              backgroundColor: Colors.green,
            ),
          );
          widget.onComplete?.call();
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to submit rating');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 40),
                    Text(
                      widget.isDriver ? 'Rate Passenger' : 'Rate Your Driver',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: widget.onSkip,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Partner avatar and name
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      const Color(0xFF0066CC).withValues(alpha: 0.2),
                  backgroundImage: widget.partnerImage != null
                      ? NetworkImage(widget.partnerImage!)
                      : null,
                  child: widget.partnerImage == null
                      ? Text(
                          widget.partnerName.isNotEmpty
                              ? widget.partnerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066CC),
                          ),
                        )
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  widget.partnerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'How was your ${widget.isDriver ? 'passenger' : 'ride'}?',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                // Star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () => setState(() => _rating = index + 1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 40,
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Text(
                  _getRatingText(),
                  style: TextStyle(
                    color: _getRatingColor(),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),

                // Category chips (show only for 4-5 star ratings)
                if (_rating >= 4) ...[
                  const Text(
                    'What did you like?',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _categories.map((category) {
                      final isSelected = _selectedCategories.contains(category);
                      return FilterChip(
                        label: Text(category),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category);
                            } else {
                              _selectedCategories.remove(category);
                            }
                          });
                        },
                        selectedColor:
                            const Color(0xFF0066CC).withValues(alpha: 0.3),
                        checkmarkColor: const Color(0xFF0066CC),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],

                // Feedback text field
                TextField(
                  controller: _feedbackController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: _rating <= 3
                        ? 'Tell us what went wrong...'
                        : 'Add a comment (optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRating,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066CC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Rating',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Skip button
                TextButton(
                  onPressed: widget.onSkip,
                  child: const Text(
                    'Skip for now',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getRatingText() {
    switch (_rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return 'Tap to rate';
    }
  }

  Color _getRatingColor() {
    switch (_rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
