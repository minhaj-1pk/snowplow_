import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class DirectRequestSENDPAGE extends StatefulWidget {
  const DirectRequestSENDPAGE({super.key});

  @override
  _DirectRequestSENDPAGEState createState() => _DirectRequestSENDPAGEState();
}

class _DirectRequestSENDPAGEState extends State<DirectRequestSENDPAGE> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String urgency = "";
  String selectedService = "";
  String selectedCompany = "";
  Map<String, String> companyNameToId = {};
  String id = '';

  List<String> serviceTypes = [];
  List<String> companyList = [];

  final TextEditingController areaController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  bool isSubmitting = false;
  final List<Color> myGradientColors = [
    Colors.blue.shade200,
    const Color.fromARGB(255, 122, 189, 231),
    const Color.fromARGB(255, 181, 211, 232),
  ];

  @override
  void initState() {
    super.initState();
    fetchServiceTypes();
    fetchCompanies();
    _getCurrentLocation();
  }

  Future<void> fetchServiceTypes() async {
    try {
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/services/list"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"per_page": "10", "page": "0", "api_mode": "test"}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> services = data['data'];

        setState(() {
          serviceTypes =
              services
                  .map<String>((item) => item['service_type']?.toString() ?? '')
                  .toList();
        });
      }
    } catch (e) {
      print("Service type fetch error: $e");
    }
  }

  Future<void> fetchCompanies() async {
    try {
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/agencies/list"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"per_page": "100", "page": "0", "api_mode": "test"}),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> companies = data['data'];

        setState(() {
          companyList =
              companies
                  .map<String>((item) => item['agency_name']?.toString() ?? '')
                  .toList();
          companyNameToId = {
            for (var item in companies)
              item['agency_name'].toString(): item['agency_id'].toString(),
          };
        });
      }
    } catch (e) {
      print("Company list error: $e");
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location permission denied')));
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        String address =
            "${placemark.street ?? ''}, ${placemark.locality ?? ''}, ${placemark.administrativeArea ?? ''}";
        setState(() {
          locationController.text = address;
        });
      }
    } catch (e) {
      print("Location error: $e");
    }
  }

  Future<void> _submitDirectRequest() async {
    if (selectedDate == null || selectedTime == null) {
      _showError("Please select date and time");
      return;
    }

    if (selectedCompany.isEmpty ||
        selectedService.isEmpty ||
        urgency.isEmpty ||
        areaController.text.isEmpty ||
        locationController.text.isEmpty) {
      _showError("Please fill all fields");
      return;
    }

    setState(() => isSubmitting = true);

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');

    if (userId == null) {
      _showError("User ID not found");
      setState(() => isSubmitting = false);
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    String formattedDate =
        "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
    String formattedTime =
        "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}";

    String base64Image = '';
    String imageExt = '';

    if (_image != null) {
      File imageFile = File(_image!.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      base64Image = base64Encode(imageBytes);
      imageExt = _image!.path.split('.').last;
    }

    Map<String, dynamic> requestData = {
      "customer_id": userId,
      "service_type": selectedService,
      "service_city": locationController.text,
      "service_area": areaController.text,
      "service_street": locationController.text,
      "preferred_date": formattedDate,
      "preferred_time": formattedTime,
      "image": base64Image,
      "image_ext": imageExt,
      "service_latitude": position.latitude,
      "service_longitude": position.longitude,
      "urgency_level": urgency,
      "agency_id": companyNameToId[selectedCompany],
      "api_mode": "test",
    };

    try {
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/requests/companyrequest"),
        headers: {'Content-Type': 'application/json', 'api_mode': 'test'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Direct Request Submitted",
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.green[600],
          ),
        );
        _resetForm();
      } else {
        print("Server Error: ${response.body}");
        _showError("Failed to submit request");
      }
    } catch (e) {
      print("Submission error: $e");
      _showError("Network error occurred");
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.red[600],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      selectedDate = null;
      selectedTime = null;
      _image = null;
      urgency = '';
      selectedService = '';
      selectedCompany = '';
      areaController.clear();
      locationController.clear();
    });
  }

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = picked);
    }
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) setState(() => selectedTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: false,

      // appBar: AppBar(
      //   backgroundColor: Colors.blue.shade300,
      //   elevation: 0,
      //   title: const Text("Direct Request"),
      //   centerTitle: true,
      //   titleTextStyle: TextStyle(
      //     fontSize: 22,
      //     fontWeight: FontWeight.bold,
      //     color: Colors.white,
      //   ),
      // ),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Colors.blue.shade400,
          elevation: 0,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade400],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          title: Text("Direct Request"),
          centerTitle: true,
          // ...other properties...
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: myGradientColors,
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromARGB(255, 72, 156, 225),
                    Color(0xFF42A5F5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Glass form center
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(maxWidth: 500),
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 40,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 30,
                          offset: Offset(0, 7),
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: 5),
                            buildDropdown(
                              label: "Select Company",

                              icon: Icons.business,
                              selectedValue: selectedCompany,
                              options: companyList,
                              onChanged:
                                  (val) => setState(
                                    () => selectedCompany = val ?? "",
                                  ),
                            ),
                            const SizedBox(height: 16),
                            buildDropdown(
                              label: "Select Service",
                              icon: Icons.miscellaneous_services_outlined,
                              selectedValue: selectedService,
                              options: serviceTypes,
                              onChanged:
                                  (val) => setState(
                                    () => selectedService = val ?? "",
                                  ),
                            ),
                            const SizedBox(height: 16),
                            buildTextField(
                              label: "Area",
                              icon: Icons.area_chart,
                              controller: areaController,
                            ),
                            const SizedBox(height: 16),
                            buildLocationField(),
                            const SizedBox(height: 16),
                            buildUrgencySelector(),
                            const SizedBox(height: 18),
                            buildDateTimeButtons(),
                            const SizedBox(height: 18),
                            _image == null
                                ? DottedBorderPlaceholder()
                                : AspectRatio(
                                  aspectRatio: 16 / 9,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 14,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(
                                        File(_image!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                            const SizedBox(height: 12),
                            Center(
                              child: ElevatedButton.icon(
                                onPressed: _pickImage,
                                icon: Icon(Icons.image),
                                label: Text("Select Image"),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.blueAccent
                                      .withOpacity(0.9),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            Center(
                              child: AnimatedContainer(
                                duration: Duration(milliseconds: 250),
                                curve: Curves.easeInOut,
                                child: ElevatedButton.icon(
                                  onPressed:
                                      isSubmitting
                                          ? null
                                          : _submitDirectRequest,
                                  icon:
                                      isSubmitting
                                          ? SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.7,
                                              color: Colors.white,
                                            ),
                                          )
                                          : Icon(Icons.send_rounded),
                                  label: Text(
                                    isSubmitting
                                        ? "Submitting..."
                                        : "Submit Request",
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.indigo,
                                    padding: EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    textStyle: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDropdown({
    required String label,
    required IconData icon,
    required String selectedValue,
    required List<String> options,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: selectedValue.isNotEmpty ? selectedValue : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white38),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
      dropdownColor: Colors.white,
      iconEnabledColor: Colors.blueAccent,
      onChanged: onChanged,
      items:
          options
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.grey[600], size: 18),
                      SizedBox(width: 8),
                      Text(value, style: TextStyle(color: Colors.black)),
                    ],
                  ),
                ),
              )
              .toList(),
      style: TextStyle(color: Colors.black),
    );
  }

  Widget buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
  }) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.white, fontSize: 17),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.white70),
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.white30),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.blueAccent, width: 2),
        ),
      ),
    );
  }

  Widget buildLocationField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: locationController,
            readOnly: true,
            style: TextStyle(color: Colors.white, fontSize: 17),
            decoration: InputDecoration(
              prefixIcon: Icon(
                Icons.my_location_outlined,
                color: Colors.white70,
              ),
              labelText: "Location",
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.white30),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.blueAccent, width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Tooltip(
          message: "Get Current Location",
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.withOpacity(0.87),
              foregroundColor: Colors.white,
              padding: EdgeInsets.all(13),
              shape: CircleBorder(),
              elevation: 0,
            ),
            onPressed: _getCurrentLocation,
            child: Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }

  Widget buildUrgencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Urgency Level",
          style: TextStyle(
            color: Colors.white70,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        Row(
          children: [
            Radio(
              value: "Urgent",
              groupValue: urgency,
              onChanged: (val) => setState(() => urgency = val ?? ""),
              activeColor: Colors.white,
              fillColor: MaterialStateProperty.all(Colors.redAccent),
            ),
            const Text("Urgent", style: TextStyle(color: Colors.white)),
            Radio(
              value: "Normal",
              groupValue: urgency,
              onChanged: (val) => setState(() => urgency = val ?? ""),
              activeColor: Colors.white,
              fillColor: MaterialStateProperty.all(Colors.blueAccent),
            ),
            const Text("Normal", style: TextStyle(color: Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget buildDateTimeButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickDate,
            icon: Icon(Icons.date_range),
            label: Text(
              selectedDate == null
                  ? "Pick Date"
                  : "${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _pickTime,
            icon: Icon(Icons.access_time),
            label: Text(
              selectedTime == null
                  ? "Pick Time"
                  : "${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}",
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dashed border image placeholder.
class DottedBorderPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            width: 2,
            color: Colors.white.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Center(
          child: Text(
            "No image selected",
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
