import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class PermissionTestWidget extends StatefulWidget {
  @override
  State<PermissionTestWidget> createState() => _PermissionTestWidgetState();
}

class _PermissionTestWidgetState extends State<PermissionTestWidget> {
  Map<String, PermissionStatus> permissionStatuses = {};
  String androidVersion = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      isLoading = true;
    });

    // Get Android version info
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      androidVersion =
          'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt})';
    }

    // Check various permissions
    final permissions = [
      Permission.storage,
      Permission.camera,
      Permission.microphone,
      if (Platform.isAndroid) ...[
        Permission.photos,
        Permission.videos,
        Permission.audio,
        Permission.manageExternalStorage,
      ],
    ];

    Map<String, PermissionStatus> statuses = {};
    for (final permission in permissions) {
      try {
        final status = await permission.status;
        statuses[permission.toString()] = status;
      } catch (e) {
        print('Error checking permission $permission: $e');
      }
    }

    setState(() {
      permissionStatuses = statuses;
      isLoading = false;
    });
  }

  Future<void> _requestPermission(Permission permission) async {
    final status = await permission.request();
    setState(() {
      permissionStatuses[permission.toString()] = status;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${permission.toString()}: ${status.toString()}'),
        backgroundColor: status.isGranted ? Colors.green : Colors.red,
      ),
    );
  }

  Color _getStatusColor(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return Colors.green;
      case PermissionStatus.denied:
        return Colors.orange;
      case PermissionStatus.permanentlyDenied:
        return Colors.red;
      case PermissionStatus.restricted:
        return Colors.purple;
      case PermissionStatus.limited:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(PermissionStatus status) {
    switch (status) {
      case PermissionStatus.granted:
        return 'Granted ✓';
      case PermissionStatus.denied:
        return 'Denied ✗';
      case PermissionStatus.permanentlyDenied:
        return 'Permanently Denied ⚠️';
      case PermissionStatus.restricted:
        return 'Restricted 🔒';
      case PermissionStatus.limited:
        return 'Limited 📏';
      default:
        return 'Unknown ❓';
    }
  }

  String _getPermissionName(String permission) {
    if (permission.contains('storage')) return 'Storage';
    if (permission.contains('camera')) return 'Camera';
    if (permission.contains('microphone')) return 'Microphone';
    if (permission.contains('photos')) return 'Photos';
    if (permission.contains('videos')) return 'Videos';
    if (permission.contains('audio')) return 'Audio';
    if (permission.contains('manageExternalStorage'))
      return 'Manage External Storage';
    return permission;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Permission Status',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                IconButton(
                  onPressed: _checkPermissions,
                  icon: Icon(Icons.refresh),
                  tooltip: 'Refresh',
                ),
              ],
            ),

            if (androidVersion.isNotEmpty) ...[
              SizedBox(height: 8),
              Text(
                androidVersion,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            SizedBox(height: 16),

            if (isLoading)
              Center(child: CircularProgressIndicator())
            else
              ...permissionStatuses.entries.map((entry) {
                final permission = entry.key;
                final status = entry.value;
                final permissionName = _getPermissionName(permission);

                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          permissionName,
                          style: TextStyle(fontSize: 14),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: _getStatusColor(status)),
                          ),
                          child: Text(
                            _getStatusText(status),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getStatusColor(status),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      if (status != PermissionStatus.granted)
                        ElevatedButton(
                          onPressed: () {
                            // Find the Permission enum from string
                            Permission? perm;
                            if (permission.contains('storage'))
                              perm = Permission.storage;
                            else if (permission.contains('camera'))
                              perm = Permission.camera;
                            else if (permission.contains('microphone'))
                              perm = Permission.microphone;
                            else if (permission.contains('photos'))
                              perm = Permission.photos;
                            else if (permission.contains('videos'))
                              perm = Permission.videos;
                            else if (permission.contains('audio'))
                              perm = Permission.audio;
                            else if (permission.contains(
                              'manageExternalStorage',
                            ))
                              perm = Permission.manageExternalStorage;

                            if (perm != null) {
                              _requestPermission(perm);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: Size(60, 30),
                          ),
                          child: Text(
                            'Request',
                            style: TextStyle(fontSize: 10),
                          ),
                        )
                      else
                        SizedBox(width: 60),
                    ],
                  ),
                );
              }),

            SizedBox(height: 16),

            // Info box
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ℹ️ Permission Info',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Android 13+: Photos/Videos/Audio permissions replace Storage\n'
                    '• Storage permission only needed for Android 12 and below\n'
                    '• Files saved to app-specific directories don\'t need permissions',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
