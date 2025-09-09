import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class direct_to_agency extends StatefulWidget {
  final agencyid;
  const direct_to_agency({super.key, this.agencyid});

  _direct_to_agencyState createState() => _direct_to_agencyState();
}

class _direct_to_agencyState extends State<direct_to_agency> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  String urgency = "";
  String selectedService = "";
  String selectedCompany = "";
  dynamic companyNameToId = "";
  String id = '';
  String? agentid;

  List<String> serviceTypes = [];
  List<String> companyList = [];

  final TextEditingController areaController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchServiceTypes();
    fetchCompanies();
    _getCurrentLocation();
    agentid = widget.agencyid;
  }

  // Future<void> fetchServiceTypes() async {
  //   try {
  //     final response = await http.post(
  //       Uri.parse("https://snowplow.celiums.com/api/services/list"),
  //       headers: {'Content-Type': 'application/json'},
  //       body: jsonEncode({"per_page": "10", "page": "0", "api_mode": "test"}),
  //     );
  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       final List<dynamic> services = data['data'];

  //       setState(() {
  //         serviceTypes = services
  //             .map<String>((item) => item['service_type']?.toString() ?? '')
  //             .toList();
  //       });
  //     }
  //   } catch (e) {
  //     print("Service list error: $e");
  //   }
  // }
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
        });

        // for (var item in companies) {
        //   final name = item['agency_name']?.toString() ?? '';
        //  id = item['agency_id']?.toString() ?? '';
        companyNameToId = {
          for (var item in companies)
            item['agency_name'].toString(): item['agency_id'].toString(),
        };
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please select date and time")));
      return;
    }

    if (selectedService.isEmpty ||
        urgency.isEmpty ||
        areaController.text.isEmpty ||
        locationController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Please fill all fields")));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString('userId');
    //String? token = prefs.getString('token');

    if (userId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("User ID not found")));
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
      "agency_id": agentid,

      "api_mode": "test",
    };

    try {
      final response = await http.post(
        Uri.parse("https://snowplow.celiums.com/api/requests/companyrequest"),
        headers: {'Content-Type': 'application/json', 'api_mode': 'test'},
        body: jsonEncode(requestData),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Direct Request Submitted")));
        print('request COUNT$requestData');
        _resetForm();
      } else {
        print("Server Error: ${response.body}");
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to submit request")));
      }
    } catch (e) {
      print("Submission error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network error occurred")));
    }
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
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
        title: const Text("Direct Request"),
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color.fromARGB(255, 72, 156, 225), Color(0xFF42A5F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: const BoxConstraints(maxWidth: 500),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: Offset(0, 6),
                  ),
                ],
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  buildDropdown(
                    "Select Service",
                    selectedService,
                    serviceTypes,
                    (val) => setState(() => selectedService = val ?? ""),
                  ),
                  const SizedBox(height: 16),
                  buildTextField("Area", areaController),
                  const SizedBox(height: 16),
                  buildLocationField(),
                  const SizedBox(height: 16),
                  buildUrgencySelector(),
                  const SizedBox(height: 16),
                  buildDateTimeButtons(),
                  const SizedBox(height: 16),
                  _image == null
                      ? Center(
                        child: Text(
                          "No image selected",
                          style: TextStyle(color: Colors.white70),
                        ),
                      )
                      : ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(File(_image!.path), height: 150),
                      ),
                  const SizedBox(height: 12),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: Icon(Icons.image),
                      label: Text("Select Image"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _submitDirectRequest,
                      icon: Icon(Icons.send),
                      label: Text("Submit Request"),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.indigo,
                        padding: EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 24,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDropdown(
    String label,
    String selectedValue,
    List<String> options,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: selectedValue.isNotEmpty ? selectedValue : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
      ),
      dropdownColor: Colors.white,
      iconEnabledColor: Colors.white,
      onChanged: onChanged,
      items:
          options
              .map(
                (value) => DropdownMenuItem(
                  value: value,
                  child: Text(value, style: TextStyle(color: Colors.black)),
                ),
              )
              .toList(),
    );
  }

  Widget buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
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
            style: TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "Location",
              labelStyle: TextStyle(color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.1),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(Icons.my_location, color: Colors.white),
          onPressed: _getCurrentLocation,
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
          style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
        ),
        Row(
          children: [
            Radio(
              value: "Urgent",
              groupValue: urgency,
              onChanged: (val) => setState(() => urgency = val ?? ""),
              activeColor: Colors.white,
            ),
            const Text("Urgent", style: TextStyle(color: Colors.white)),
            Radio(
              value: "Normal",
              groupValue: urgency,
              onChanged: (val) => setState(() => urgency = val ?? ""),
              activeColor: Colors.white,
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
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
