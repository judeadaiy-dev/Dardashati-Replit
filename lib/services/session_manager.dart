import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dardashati/utils/logger.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  
  factory SessionManager() {
    return _instance;
  }
  
  SessionManager._internal();
  
  late SharedPreferences _prefs;
  bool _initialized = false;

  // Initialize the session manager
  Future<void> initialize() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    AppLogger.success("SESSION", "Session Manager initialized");
  }

  // Check if there's an active session and restore it
  Future<bool> restoreSession() async {
    if (!_initialized) await initialize();
    
    try {
      final currentSession = Supabase.instance.client.auth.currentSession;
      
      // If there's an active session, we're good
      if (currentSession != null) {
        AppLogger.success("SESSION", "Active session found - User is logged in");
        return true;
      }
      
      // Try to refresh the session from stored tokens
      await Supabase.instance.client.auth.refreshSession();
      final refreshedSession = Supabase.instance.client.auth.currentSession;
      
      if (refreshedSession != null) {
        AppLogger.success("SESSION", "Session refreshed successfully");
        return true;
      }
      
      AppLogger.info("SESSION", "No valid session found - User needs to login");
      return false;
    } catch (e) {
      AppLogger.trace("SESSION", "Session restoration failed: $e");
      return false;
    }
  }

  // Get current user with session check
  User? getCurrentUser() {
    return Supabase.instance.client.auth.currentUser;
  }

  // Get current session
  Session? getCurrentSession() {
    return Supabase.instance.client.auth.currentSession;
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return Supabase.instance.client.auth.currentSession != null;
  }

  // Sign out and clear session (only when user explicitly requests)
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      AppLogger.success("SESSION", "User signed out successfully");
    } catch (e) {
      AppLogger.error("SESSION", "Error during sign out", e);
      rethrow;
    }
  }

  // Save session metadata (optional: for analytics or recovery)
  Future<void> saveSessionMetadata(String userId) async {
    try {
      await _prefs.setString('last_user_id', userId);
      await _prefs.setInt('session_start_time', DateTime.now().millisecondsSinceEpoch);
      AppLogger.info("SESSION", "Session metadata saved for user: $userId");
    } catch (e) {
      AppLogger.error("SESSION", "Failed to save session metadata", e);
    }
  }

  // Get session metadata
  Map<String, dynamic> getSessionMetadata() {
    final lastUserId = _prefs.getString('last_user_id');
    final startTime = _prefs.getInt('session_start_time');
    
    return {
      'lastUserId': lastUserId,
      'sessionStartTime': startTime != null ? DateTime.fromMillisecondsSinceEpoch(startTime) : null,
    };
  }

  // Clear session metadata (called on logout)
  Future<void> clearSessionMetadata() async {
    try {
      await _prefs.remove('last_user_id');
      await _prefs.remove('session_start_time');
      AppLogger.info("SESSION", "Session metadata cleared");
    } catch (e) {
      AppLogger.error("SESSION", "Failed to clear session metadata", e);
    }
  }

  // Monitor auth state changes
  Stream<AuthState> get authStateChanges => 
    Supabase.instance.client.auth.onAuthStateChange;
}
