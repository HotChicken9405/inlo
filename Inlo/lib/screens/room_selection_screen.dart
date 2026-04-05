import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'booking_summary_screen.dart';

class RoomSelectionScreen extends StatefulWidget {
  final String propertyId;
  final Map<String, dynamic> data;

  const RoomSelectionScreen({
    super.key,
    required this.propertyId,
    required this.data,
  });

  @override
  State<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends State<RoomSelectionScreen> {
  DateTime _checkIn = DateTime.now().add(const Duration(days: 1));
  DateTime _checkOut = DateTime.now().add(const Duration(days: 3));
  int _guests = 2;

  Future<void> _pickDate(bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut.isBefore(_checkIn)) {
            _checkOut = _checkIn.add(const Duration(days: 1));
          }
        } else {
          if (picked.isAfter(_checkIn)) {
            _checkOut = picked;
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                  Text('Check-out must be after check-in')),
            );
          }
        }
      });
    }
  }

  int get _nights => _checkOut.difference(_checkIn).inDays;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  bool _isRoomBooked(Map<String, dynamic> room) {
    final bookedDates =
    List<Map<String, dynamic>>.from(room['bookedDates'] ?? []);
    for (final booking in bookedDates) {
      final bookedFrom =
      (booking['from'] as Timestamp).toDate();
      final bookedTo = (booking['to'] as Timestamp).toDate();
      if (_checkIn.isBefore(bookedTo) &&
          _checkOut.isAfter(bookedFrom)) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final roomTypes = List<Map<String, dynamic>>.from(
        widget.data['roomTypes'] ?? []);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a room',
                style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
            Text(widget.data['propertyName'] ?? '',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 12)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Date + guests selector
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(true),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text('CHECK-IN',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_formatDate(_checkIn),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(Icons.arrow_forward,
                          color: Colors.grey.shade400, size: 16),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickDate(false),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text('CHECK-OUT',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(_formatDate(_checkOut),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Guests',
                        style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14)),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            if (_guests > 1)
                              setState(() => _guests--);
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          color: Colors.blue.shade600,
                        ),
                        Text('$_guests',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        IconButton(
                          onPressed: () => setState(() => _guests++),
                          icon: const Icon(Icons.add_circle_outline),
                          color: Colors.blue.shade600,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${roomTypes.length} room type${roomTypes.length != 1 ? 's' : ''} available for $_nights night${_nights != 1 ? 's' : ''}',
                style: TextStyle(
                    color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Room list
          Expanded(
            child: roomTypes.isEmpty
                ? Center(
              child: Text('No room types added by host yet',
                  style:
                  TextStyle(color: Colors.grey.shade400)),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16),
              itemCount: roomTypes.length,
              itemBuilder: (context, index) {
                final room = roomTypes[index];
                final isBooked = _isRoomBooked(room);
                final price =
                (room['price'] as num).toDouble();
                final total = price * _nights;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color:
                        Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Text(room['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15)),
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.end,
                            children: [
                              Text(
                                'LKR ${price.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color:
                                    Colors.blue.shade600,
                                    fontWeight:
                                    FontWeight.bold,
                                    fontSize: 15),
                              ),
                              Text('/night',
                                  style: TextStyle(
                                      color: Colors
                                          .grey.shade400,
                                      fontSize: 11)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _chip(room['bedType'] ?? ''),
                          const SizedBox(width: 8),
                          _chip(
                              'Max ${room['maxGuests']}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3),
                                decoration: BoxDecoration(
                                  color: isBooked
                                      ? Colors.red.shade50
                                      : Colors.green.shade50,
                                  borderRadius:
                                  BorderRadius.circular(6),
                                ),
                                child: Text(
                                  isBooked
                                      ? 'Sold out'
                                      : 'Available',
                                  style: TextStyle(
                                    color: isBooked
                                        ? Colors.red.shade600
                                        : Colors.green
                                        .shade600,
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Total: LKR ${total.toStringAsFixed(0)}',
                                style: TextStyle(
                                    color:
                                    Colors.grey.shade600,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                          if (!isBooked)
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        BookingSummaryScreen(
                                          propertyId:
                                          widget.propertyId,
                                          propertyData:
                                          widget.data,
                                          room: room,
                                          checkIn: _checkIn,
                                          checkOut: _checkOut,
                                          guests: _guests,
                                          nights: _nights,
                                        ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.black87,
                                foregroundColor: Colors.white,
                                padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(
                                        8)),
                              ),
                              child: const Text('Book now'),
                            ),
                        ],
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

  Widget _chip(String label) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: const TextStyle(fontSize: 12)),
    );
  }
}