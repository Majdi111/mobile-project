import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../controllers/service_controller.dart';
import '../controllers/booking_controller.dart';
import '../controllers/auth_controller.dart';
import '../models/service_model.dart';

class BrowseServicesPage extends StatefulWidget {
  const BrowseServicesPage({super.key});

  @override
  State<BrowseServicesPage> createState() => _BrowseServicesPageState();
}

class _BrowseServicesPageState extends State<BrowseServicesPage> {
  final ServiceController _serviceController = ServiceController();
  final BookingController _bookingController = BookingController();
  final AuthController _authController = AuthController();

  String selectedCategory = 'All';
  final List<String> categories = [
    'All',
    'Haircut',
    'Shaving',
    'Beard Trim',
    'Hair Color',
    'Styling',
    'Facial',
    'Massage'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Services'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // Category Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),

          // Services List
          Expanded(
            child: StreamBuilder<List<ServiceModel>>(
              stream: selectedCategory == 'All'
                  ? _serviceController.getAllServices()
                  : _serviceController.getServicesByCategory(selectedCategory),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.content_cut,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No services available',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final services = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: services.length,
                  itemBuilder: (context, index) {
                    final service = services[index];
                    return _buildServiceCard(service);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceModel service) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showBookingDialog(service),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Center(
                  child: Icon(
                    _getCategoryIcon(service.category),
                    size: 48,
                    color: Colors.blue[700],
                  ),
                ),
              ),
            ),
            // Service Details
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.serviceName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.providerName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${service.price.toStringAsFixed(2)} TND',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        '${service.duration} min',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
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
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'haircut':
        return Icons.content_cut;
      case 'shaving':
        return Icons.face;
      case 'beard trim':
        return Icons.face_retouching_natural;
      case 'hair color':
        return Icons.color_lens;
      case 'styling':
        return Icons.style;
      case 'facial':
        return Icons.spa;
      case 'massage':
        return Icons.self_improvement;
      default:
        return Icons.content_cut;
    }
  }

  void _showBookingDialog(ServiceModel service) {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Book ${service.serviceName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Provider: ${service.providerName}'),
              const SizedBox(height: 8),
              Text('Price: ${service.price.toStringAsFixed(2)} TND'),
              const SizedBox(height: 8),
              Text('Duration: ${service.duration} minutes'),
              const Divider(height: 24),
              const Text(
                'Select Date & Time',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(
                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setDialogState(() => selectedDate = date);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.access_time),
                title: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setDialogState(() => selectedTime = time);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => _confirmBooking(
                service,
                DateTime(
                  selectedDate.year,
                  selectedDate.month,
                  selectedDate.day,
                  selectedTime.hour,
                  selectedTime.minute,
                ),
              ),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmBooking(
      ServiceModel service, DateTime bookingDate) async {
    Navigator.pop(context);

    final user = _authController.getCurrentUser();
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to book a service')),
      );
      return;
    }

    // Get client name from Firestore
    final db = FirebaseFirestore.instance;
    final clientDoc = await db.collection('clients').doc(user.uid).get();
    final clientName = clientDoc.data()?['full_name'] ?? 'Client';

    final result = await _bookingController.createBooking(
      clientId: user.uid,
      clientName: clientName,
      providerId: service.providerId,
      providerName: service.providerName,
      serviceId: service.id,
      serviceName: service.serviceName,
      price: service.price,
      duration: service.duration,
      bookingDate: bookingDate,
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking confirmed!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Booking failed: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
