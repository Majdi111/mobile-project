import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ClientNameWidget extends StatelessWidget {
  final String clientId;
  final TextStyle? style;
  final String fallbackName;

  const ClientNameWidget({
    super.key,
    required this.clientId,
    this.style,
    this.fallbackName = 'Client',
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clients')
          .doc(clientId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Text(fallbackName, style: style);
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Text(fallbackName, style: style);
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;
        final name = data?['full_name'] ?? fallbackName;

        return Text(name, style: style);
      },
    );
  }
}
