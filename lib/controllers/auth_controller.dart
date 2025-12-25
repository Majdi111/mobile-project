import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class AuthController {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ============================================
  // SIGN UP - Save to correct collection
  // ============================================
  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String gender,
    required DateTime dateOfBirth,
    required String userType, // ⭐ "client" or "provider"
    GeoPoint? location,
    int? startingHour,
    int? closingHour,
  }) async {
    try {
      // Step 1: Create user in Firebase Auth
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Step 2: Prepare user data
      Map<String, dynamic> userData = {
        'email': email,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'gender': gender,
        'date_birth': Timestamp.fromDate(dateOfBirth),
        'location': location ?? const GeoPoint(0, 0),
        'profileImage': '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Step 3: Add extra fields for providers
      if (userType == 'provider') {
        userData['bio'] = '';
        userData['rating'] = 0.0;
        userData['totalReviews'] = 0;
        userData['isAvailable'] = true;
        if (startingHour != null) userData['starting_hour'] = startingHour;
        if (closingHour != null) userData['closing_hour'] = closingHour;
      }

      // ⭐ Step 4: Save to the CORRECT collection based on userType
      String collection = userType == 'client' ? 'clients' : 'providers';
      await _db.collection(collection).doc(uid).set(userData);

      return {
        'success': true,
        'userType': userType,
        'uid': uid,
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'Password is too weak. ';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists with this email. ';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email address.';
          break;
        default:
          errorMessage = 'Auth Error: ${e.code} - ${e.message}';
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // ============================================
  // GET CURRENT GPS LOCATION
  // ============================================
  Future<Map<String, dynamic>?> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return null;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        return null;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
      };
    } catch (e) {
      return null;
    }
  }

  // ============================================
  // SIGN IN - Fetch from correct collection ⭐
  // ============================================
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
    required String userType, // ⭐ "client" or "provider"
  }) async {
    try {
      // Step 1: Sign in with Firebase Auth
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // ⭐ Step 2: Fetch from the CORRECT collection based on userType
      String collection = userType == 'client' ? 'clients' : 'providers';
      DocumentSnapshot userDoc =
          await _db.collection(collection).doc(uid).get();

      // Step 3: Check if user exists in the selected collection
      if (!userDoc.exists) {
        // User signed in but doesn't exist in this collection
        await _auth.signOut(); // Sign them out
        return {
          'success': false,
          'error':
              'No $userType account found with this email.  Did you select the correct account type?',
        };
      }

      Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;

      return {
        'success': true,
        'userType': userType,
        'userData': userData,
        'uid': uid,
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No user found with this email. ';
          break;
        case 'wrong-password':
          errorMessage = 'Invalid password.  Please try again.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled. ';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many attempts. Please try again later.';
          break;
        default:
          errorMessage = 'An error occurred. Please try again. ';
      }
      return {'success': false, 'error': errorMessage};
    }
  }

  // ============================================
  // SIGN OUT
  // ============================================
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ============================================
  // FORGOT PASSWORD - Send password reset email
  // ============================================
  Future<Map<String, dynamic>> resetPassword({
    required String email,
  }) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Password reset email sent! Please check your inbox.',
      };
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'No account found with this email.';
          break;
        case 'invalid-email':
          errorMessage = 'Invalid email format.';
          break;
        default:
          errorMessage = 'Error: ${e.message}';
      }
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': 'Error: $e'};
    }
  }

  // ============================================
  // GET CURRENT USER
  // ============================================
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}
