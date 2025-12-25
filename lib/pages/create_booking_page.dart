import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/auth_controller.dart';
import '../controllers/booking_controller.dart';

class CreateBookingPage extends StatefulWidget {
  final String? preselectedProviderId;
  final Map<String, dynamic>? preselectedProviderData;

  const CreateBookingPage({
    super.key,
    this.preselectedProviderId,
    this.preselectedProviderData,
  });

  @override
  State<CreateBookingPage> createState() => _CreateBookingPageState();
}

class _CreateBookingPageState extends State<CreateBookingPage> {
  final AuthController _authController = AuthController();
  final BookingController _bookingController = BookingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();

  int _currentStep = 0;
  String _searchQuery = '';
  
  // Step 1: Provider Selection
  Map<String, dynamic>? _selectedProvider;
  List<Map<String, dynamic>> _selectedServices = [];
  
  // Step 2: Date Selection
  DateTime? _selectedDate;
  
  // Step 3: Time Selection
  String?  _selectedTime;
  List<String> _availableTimeSlots = [];
  
  bool _isLoading = false;
  bool _isPreselected = false;

  @override
  void initState() {
    super.initState();
    // Set preselected provider if provided
    if (widget.preselectedProviderId != null && widget.preselectedProviderData != null) {
      _selectedProvider = {
        'id': widget.preselectedProviderId,
        ...widget.preselectedProviderData!,
      };
      _isPreselected = true;
      _availableTimeSlots = _generateTimeSlots();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  // Calculate total duration and price
  int get _totalDuration {
    return _selectedServices.fold(0, (sum, service) => sum + (service['duration'] as int? ?? 0));
  }
  
  double get _totalPrice {
    return _selectedServices.fold(0.0, (sum, service) => sum + (service['price'] as num? ?? 0).toDouble());
  }

  // Generate time slots based on provider's working hours
  List<String> _generateTimeSlots() {
    if (_selectedProvider == null) return [];
    
    final startingHour = _selectedProvider!['starting_hour'] as int?;
    final closingHour = _selectedProvider!['closing_hour'] as int?;
    
    // Only generate time slots if provider has working hours set
    if (startingHour == null || closingHour == null) return [];
    
    List<String> slots = [];
    for (int hour = startingHour; hour < closingHour; hour++) {
      slots.add('${hour.toString().padLeft(2, '0')}:00');
    }
    
    return slots;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Check if provider data was passed as arguments
    if (!_isPreselected) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null && args.containsKey('providerId')) {
        setState(() {
          _selectedProvider = {
            'id': args['providerId'],
            ...args['providerData'] as Map<String, dynamic>,
          };
          _isPreselected = true;
          _availableTimeSlots = _generateTimeSlots();
          // Start from step 0 to show services
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Booking'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _onStepContinue,
        onStepCancel: _onStepCancel,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                if (_currentStep < 3)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style:  ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor:  Colors.white,
                    ),
                    child: Text(_currentStep == 2 ? 'Continue' : 'Next'),
                  ),
                if (_currentStep == 3)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _confirmBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor:  Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Confirm Booking'),
                  ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed:  details.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text('Select Provider & Services'),
            content: _buildProviderSelection(),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Select Date'),
            content: _buildDateSelection(),
            isActive:  _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title: const Text('Select Time'),
            content: _buildTimeSelection(),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
          ),
          Step(
            title:  const Text('Confirm'),
            content: _buildConfirmation(),
            isActive: _currentStep >= 3,
            state: _currentStep > 3 ? StepState.complete : StepState.indexed,
          ),
        ],
      ),
    );
  }

  Widget _buildProviderSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Bar
        if (!_isPreselected)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Search providers by name or email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
        if (_isPreselected) ...[
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Provider preselected: ${_selectedProvider?['full_name'] ?? ''}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedProvider = null;
                        _selectedServices = [];
                        _isPreselected = false;
                      });
                    },
                    child: const Text('Change'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Choose a provider:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _db.collection('providers').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No providers available'));
            }

            // Filter providers based on search query
            final filteredProviders = snapshot.data!.docs.where((provider) {
              if (_searchQuery.isEmpty) return true;
              
              final data = provider.data() as Map<String, dynamic>;
              final fullName = (data['full_name'] ?? '').toString().toLowerCase();
              final email = (data['email'] ?? '').toString().toLowerCase();
              
              return fullName.contains(_searchQuery) || email.contains(_searchQuery);
            }).toList();

            if (filteredProviders.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No providers found',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Try adjusting your search',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredProviders.length,
              itemBuilder: (context, index) {
                final provider = filteredProviders[index];
                final data = provider.data() as Map<String, dynamic>;
                final isSelected = _selectedProvider?['id'] == provider.id;

                return Card(
                  color: isSelected ? Colors.blue[50] : null,
                  elevation: isSelected ? 4 : 1,
                  child: ExpansionTile(
                    initiallyExpanded: isSelected && _isPreselected,
                    leading: CircleAvatar(
                      backgroundColor: isSelected ? Colors.blue : Colors.blue[100],
                      child: Text(
                        _getInitial(data['full_name']),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                    title: Text(
                      data['full_name'] ?? 'Provider',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle, color: Colors.blue)
                        : IconButton(
                            icon: const Icon(Icons.arrow_forward),
                            onPressed: () {
                              setState(() {
                                _selectedProvider = {
                                  'id': provider.id,
                                  ...data,
                                };
                                _selectedServices = [];
                                _availableTimeSlots = _generateTimeSlots();
                              });
                            },
                          ),
                    children: isSelected
                        ? [
                            StreamBuilder<QuerySnapshot>(
                              stream: _db
                                  .collection('services')
                                  .where('provider_id', isEqualTo: provider.id)
                                  .where('is_available', isEqualTo: true)
                                  .snapshots(),
                              builder: (context, serviceSnapshot) {
                                if (!serviceSnapshot.hasData ||
                                    serviceSnapshot.data!.docs.isEmpty) {
                                  return const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text('No services available'),
                                  );
                                }

                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                      child: Text(
                                        'Select services (you can select multiple):',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: serviceSnapshot.data!.docs.length,
                                      itemBuilder: (context, serviceIndex) {
                                        final service = serviceSnapshot.data!.docs[serviceIndex];
                                        final serviceData = service.data() as Map<String, dynamic>;
                                        final isServiceSelected = _selectedServices.any(
                                          (s) => s['id'] == service.id,
                                        );

                                        return CheckboxListTile(
                                          value: isServiceSelected,
                                          onChanged: (checked) {
                                            setState(() {
                                              if (checked == true) {
                                                _selectedServices.add({
                                                  'id': service.id,
                                                  ...serviceData,
                                                });
                                              } else {
                                                _selectedServices.removeWhere(
                                                  (s) => s['id'] == service.id,
                                                );
                                              }
                                            });
                                          },
                                          title: Text(
                                            serviceData['service_name'] ?? 'Service',
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                          subtitle: Text(
                                            '${serviceData['price']} TND • ${serviceData['duration']} min',
                                            style: const TextStyle(fontSize: 12),
                                          ),
                                          secondary: const Icon(Icons.cut, size: 20),
                                          activeColor: Colors.blue,
                                        );
                                      },
                                    ),
                                    if (_selectedServices.isNotEmpty) ...[
                                      const Divider(),
                                      Container(
                                        margin: const EdgeInsets.all(16),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.green[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.green[200]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                                                const SizedBox(width: 8),
                                                Text(
                                                  '${_selectedServices.length} service(s) selected',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green[900],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Total Duration:',
                                                  style: TextStyle(color: Colors.grey[700]),
                                                ),
                                                Text(
                                                  '$_totalDuration min',
                                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  'Total Price:',
                                                  style: TextStyle(color: Colors.grey[700]),
                                                ),
                                                Text(
                                                  '${_totalPrice.toStringAsFixed(2)} TND',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.green,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                );
                              },
                            ),
                          ]
                        : [],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose your preferred date:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        if (_selectedProvider != null && _selectedServices.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue[100],
                        child: Text(
                          _getInitial(_selectedProvider!['full_name']),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedProvider!['full_name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              '${_selectedServices.length} service(s) selected',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  ...(_selectedServices.map((service) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.cut, size: 16, color: Colors.grey),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                service['service_name'] ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                            Text(
                              '${service['duration']} min',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ))),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Duration:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$_totalDuration min',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        CalendarDatePicker(
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
          onDateChanged: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
        ),
        if (_selectedDate != null)
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.green),
                  const SizedBox(width: 12),
                  Text(
                    'Selected: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTimeSelection() {
    final now = DateTime.now();
    final isToday = _selectedDate != null &&
        _selectedDate!.year == now.year &&
        _selectedDate!.month == now.month &&
        _selectedDate!.day == now.day;
    
    if (_selectedProvider == null || _selectedDate == null) {
      return const SizedBox();
    }
    
    return StreamBuilder<DocumentSnapshot>(
      stream: _db
          .collection('providers')
          .doc(_selectedProvider!['id'])
          .snapshots(),
      builder: (context, providerSnapshot) {
        // Get working hours for the provider
        final providerData = providerSnapshot.data?.data() as Map<String, dynamic>? ?? {};
        final startingHour = providerData['starting_hour'] as int? ?? 9;
        final closingHour = providerData['closing_hour'] as int? ?? 18;
        
        // Provider is always open (working hours are already set)
        final isOpenToday = true;
        final startTime = '${startingHour.toString().padLeft(2, '0')}:00';
        final endTime = '${closingHour.toString().padLeft(2, '0')}:00';
        
        return StreamBuilder<QuerySnapshot>(
          stream: _db
              .collection('bookings')
              .where('provider_id', isEqualTo: _selectedProvider!['id'])
              .snapshots(),
          builder: (context, snapshot) {
            // Get booked time ranges for the selected date
            List<Map<String, DateTime>> bookedRanges = [];
            
            if (snapshot.hasData) {
              for (var doc in snapshot.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;
                final status = data['status'] ?? '';
                
                // Only consider confirmed or pending bookings (not cancelled)
                if (status == 'confirmed' || status == 'pending') {
                  final bookingDate = (data['booking_date'] as Timestamp).toDate();
                  
                  // Check if booking is on the selected date
                  if (bookingDate.year == _selectedDate!.year &&
                      bookingDate.month == _selectedDate!.month &&
                      bookingDate.day == _selectedDate!.day) {
                    final duration = data['total_duration'] ?? 60;
                    final endTime = bookingDate.add(Duration(minutes: duration));
                    bookedRanges.add({
                      'start': bookingDate,
                      'end': endTime,
                    });
                  }
                }
              }
            }
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose your preferred time:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, color: Colors.blue),
                            const SizedBox(width: 12),
                            Text(
                              '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.timer, color: Colors.orange, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Duration: $_totalDuration minutes',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (!isOpenToday) ...[
                  Card(
                    color: Colors.orange[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Provider is not available on this day',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  const Text(
                    'Available time slots:',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableTimeSlots.map((time) {
                      final isSelected = _selectedTime == time;
                      
                      // Parse time slot
                      final timeParts = time.split(':');
                      final slotHour = int.tryParse(timeParts[0]) ?? 0;
                      final slotMinute = int.tryParse(timeParts[1]) ?? 0;
                      
                      final slotStart = DateTime(
                        _selectedDate!.year,
                        _selectedDate!.month,
                        _selectedDate!.day,
                        slotHour,
                        slotMinute,
                      );
                      final slotEnd = slotStart.add(Duration(minutes: _totalDuration));
                      
                      // Check if time is within working hours
                      bool isOutsideWorkingHours = false;
                      if (isOpenToday) {
                        final slotTimeInMinutes = slotHour * 60 + slotMinute;
                        
                        final startParts = startTime.split(':');
                        final startHour = int.tryParse(startParts[0]) ?? 9;
                        final startMinute = int.tryParse(startParts[1]) ?? 0;
                        final startTimeInMinutes = startHour * 60 + startMinute;
                        
                        final endParts = endTime.split(':');
                        final endHour = int.tryParse(endParts[0]) ?? 17;
                        final endMinute = int.tryParse(endParts[1]) ?? 0;
                        final endTimeInMinutes = endHour * 60 + endMinute;
                        
                        // Check if booking end time exceeds working hours
                        final slotEndTimeInMinutes = slotTimeInMinutes + _totalDuration;
                        
                        isOutsideWorkingHours = slotTimeInMinutes < startTimeInMinutes || 
                                               slotEndTimeInMinutes > endTimeInMinutes;
                      }
                      
                      // Check if the time slot has passed (only for today)
                      bool isPast = isToday && slotStart.isBefore(now);
                      
                      // Check if the time slot conflicts with existing bookings
                      bool hasConflict = bookedRanges.any((range) {
                        // Check if there's any overlap
                        return (slotStart.isBefore(range['end']!) && slotEnd.isAfter(range['start']!));
                      });
                      
                      final isDisabled = isPast || hasConflict || isOutsideWorkingHours;
                      
                      return ChoiceChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(time),
                            if (hasConflict) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.event_busy,
                                size: 14,
                                color: Colors.grey[600],
                              ),
                            ],
                          ],
                        ),
                        selected: isSelected,
                        onSelected: isDisabled ? null : (selected) {
                          setState(() {
                            _selectedTime = selected ? time : null;
                          });
                        },
                        selectedColor: Colors.blue,
                        backgroundColor: isDisabled ? Colors.grey[300] : null,
                        disabledColor: Colors.grey[300],
                        labelStyle: TextStyle(
                          color: isDisabled
                              ? Colors.grey[600]
                              : (isSelected ? Colors.white : Colors.black),
                          fontWeight: FontWeight.w600,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      );
                    }).toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isOpenToday) ...[
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Working hours: $startTime - $endTime',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (isToday)
                          Row(
                            children: [
                              Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Past time slots are disabled',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        Row(
                          children: [
                            Icon(Icons.event_busy, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Slots with 🗓️ conflict with existing bookings',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConfirmation() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Please confirm your booking details:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildConfirmationRow(
                  icon: Icons.person,
                  label: 'Provider',
                  value: _selectedProvider?['full_name'] ?? '',
                ),
                const Divider(height: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cut, color: Colors.blue, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          'Services (${_selectedServices.length})',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...(_selectedServices.map((service) => Padding(
                          padding: const EdgeInsets.only(left: 32, bottom: 4),
                          child: Text(
                            '• ${service['service_name']} (${service['duration']} min)',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ))),
                  ],
                ),
                const Divider(height: 24),
                _buildConfirmationRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: _selectedDate != null
                      ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                      : '',
                ),
                const Divider(height: 24),
                _buildConfirmationRow(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: _selectedTime ?? '',
                ),
                const Divider(height: 24),
                _buildConfirmationRow(
                  icon: Icons.timer,
                  label: 'Total Duration',
                  value: '$_totalDuration minutes',
                  valueColor: Colors.orange,
                ),
                const Divider(height: 24),
                _buildConfirmationRow(
                  icon: Icons.attach_money,
                  label: 'Total Price',
                  value: '${_totalPrice.toStringAsFixed(2)} TND',
                  valueColor: Colors.green,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_selectedProvider == null || _selectedServices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a provider and at least one service'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    } else if (_currentStep == 2) {
      if (_selectedTime == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time slot'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() {
      if (_currentStep < 3) {
        _currentStep += 1;
      }
    });
  }

  void _onStepCancel() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep -= 1;
      }
    });
  }

  Future<void> _confirmBooking() async {
    if (_selectedProvider == null ||
        _selectedServices.isEmpty ||
        _selectedDate == null ||
        _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing booking information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final user = _authController.getCurrentUser();
    if (user == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Get client name
    final clientDoc = await _db.collection('clients').doc(user.uid).get();
    final clientName = clientDoc.data()?['full_name'] ?? 'Client';

    // Parse the selected time and combine with date
    final timeParts = _selectedTime!.split(':');
    if (timeParts.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid time format'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final hour = int.tryParse(timeParts[0]);
    final minute = int.tryParse(timeParts[1]);

    if (hour == null || minute == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid time format'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final bookingDateTime = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      hour,
      minute,
    );

    // Build service names list
    final serviceNames = _selectedServices
        .map((s) => s['service_name'].toString())
        .join(', ');
    
    // Build service IDs list
    final serviceIds = _selectedServices
        .map((s) => s['id'].toString())
        .toList();

    // Create booking using BookingController (this will trigger notifications)
    try {
      final result = await _bookingController.createBooking(
        clientId: user.uid,
        clientName: clientName,
        providerId: _selectedProvider!['id'],
        providerName: _selectedProvider!['full_name'],
        serviceId: serviceIds.first, // Use first service ID
        serviceName: serviceNames,
        price: _totalPrice,
        duration: _totalDuration,
        bookingDate: bookingDateTime,
      );

      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to create booking');
      }

      setState(() {
        _isLoading = false;
      });

      // Show success dialog
      if (!mounted) return;
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          title: const Text('Booking Confirmed!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your booking has been successfully created.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      '${_selectedServices.length} service(s)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year} at $_selectedTime',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    Text(
                      'Duration: $_totalDuration min',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to dashboard
              },
              child: const Text('Go to Dashboard'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.pushReplacementNamed(context, '/my-bookings');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('View My Bookings'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getInitial(dynamic name) {
    final nameStr = (name?. toString() ?? '').trim();
    return nameStr.isNotEmpty ? nameStr[0]. toUpperCase() : 'P';
  }
}