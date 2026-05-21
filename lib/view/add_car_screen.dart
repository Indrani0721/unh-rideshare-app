import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:unh_rideshare_app/services/api/car_query.dart';
import 'package:unh_rideshare_app/theme/colors.dart';
import 'package:unh_rideshare_app/services/vehicle_service.dart';
import 'package:unh_rideshare_app/services/storage_service.dart';
import 'package:unh_rideshare_app/utils/color_helper.dart';

enum LicensePlateInputMethod { typed, photo }

class AddCarScreen extends StatefulWidget {
  const AddCarScreen({super.key});

  @override
  State<AddCarScreen> createState() => _AddCarScreenState();
}

class _AddCarScreenState extends State<AddCarScreen> {
  final _vehicleDetailsFormKey = GlobalKey<FormState>();
  // Controller for the license plate text field when the user chooses to type in their license plate
  final TextEditingController _licensePlateController = TextEditingController();
  // ImagePicker instance to handle picking a license plate photo from the user's gallery when they choose that input method
  final ImagePicker _imagePicker = ImagePicker();

  final VehicleService _vehicleService = VehicleService();
  final StorageService _storageService = StorageService();
  final CarQueryApi _carQueryApi = CarQueryApi();
  final ColorHelper _colorHelper = ColorHelper();

  String? _selectedMake;
  String? _selectedModel;
  String? _selectedYear;
  String? _selectedColor;
  // State variable to track the user's selected input method for their license plate (typed in vs. photo upload)
  LicensePlateInputMethod _licensePlateInputMethod =
      LicensePlateInputMethod.typed;
  XFile? _vehiclePhoto;
  XFile? _licensePlatePhoto;
  bool _isSubmitting = false;

  // Getters to extract unique makes, models, years, and colors from the list of cars
  List<CarMake> _makeOptionsWithIds = [];
  List<String> _makeOptions = [];
  List<String> _modelOptions = [];
  List<String> _colorOptions = [];
  List<String> get _yearOptions {
    // Get today year and 10 years back to limit the year options to a reasonable range
    final currentYear = DateTime.now().year;
    final years = <String>{};
    for (int year = currentYear; year >= currentYear - 10; year--) {
      years.add(year.toString());
    }
    return years.toList();
  }

  // Method to handle when the user selects a make from the autocomplete suggestions,
  void _handleMakeSelection(String selectedMake) {
    setState(() {
      _selectedMake = selectedMake;
      _selectedModel = null;
      _modelOptions.clear();
    });

    if (selectedMake.trim().isEmpty) {
      _vehicleDetailsFormKey.currentState?.reset();
      return;
    }

    String? selectedMakeId = _makeOptionsWithIds
        .firstWhere(
          (make) => make.name.toLowerCase() == selectedMake.toLowerCase(),
          orElse: () => CarMake(name: '', id: ''),
        )
        .id;

    // Fetch the models for the selected make and update the state with the new model options
    if (_selectedYear != null && selectedMakeId.isNotEmpty) {
      _carQueryApi
          .fetchModelNamesByMakeIdAndYear(selectedMakeId, _selectedYear!)
          .then((models) {
            setState(() {
              _modelOptions = models.toList();
            });
          })
          .catchError((error) {
            debugPrint(
              'Error fetching models for $selectedMake and year $_selectedYear: $error',
            );
            setState(() {
              _modelOptions = [];
            });
          });
    } else {
      _carQueryApi
          .fetchModelNamesByMake(selectedMake)
          .then((models) {
            setState(() {
              _modelOptions = models.toList();
            });
          })
          .catchError((error) {
            debugPrint('Error fetching models for $selectedMake: $error');
            setState(() {
              _modelOptions = [];
            });
          });
    }
  }

  // Helper method to create a consistent InputDecoration for the dropdowns
  InputDecoration _inputDecoration({required String labelText}) {
    return InputDecoration(
      labelText: labelText,
      // Keep the label always visible
      floatingLabelBehavior: FloatingLabelBehavior.always,
      filled: true, // Fill the background of the dropdown
      fillColor: UNHColorsPalette.freshSnow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: UNHColorsPalette.unhWildcatBlue,
          width: 1,
        ),
      ),
    );
  }

  // Method to handle picking a license plate photo from the user's gallery using the ImagePicker package
  Future<void> _pickLicensePlatePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _licensePlatePhoto = pickedFile;
    });
  }

  // Method to handle picking a vehicle photo from the user's gallery using the ImagePicker package
  Future<void> _pickVehiclePhoto() async {
    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile == null) {
      return;
    }

    setState(() {
      _vehiclePhoto = pickedFile;
    });
  }

  @override
  void initState() {
    super.initState();
    _colorOptions = _colorHelper.colorNames();
    _carQueryApi
        .fetchMakeNames()
        .then((makes) {
          setState(() {
            _makeOptionsWithIds = makes;
          });
          // Extract just the make names for the autocomplete options
          setState(() {
            _makeOptions = makes.map((make) => make.name).toList();
          });
        })
        .catchError((error) {
          debugPrint('Error fetching makes: $error');
          setState(() {
            _makeOptions = [];
          });
        });
  }

  // Dispose of the TextEditingController when the widget is removed from the widget tree to free up resources
  @override
  void dispose() {
    _licensePlateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Back button to navigate back to the previous screen
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        // Title of the screen
        title: Text(
          'Add Vehicle',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),

      // The body of the screen contains a form with dropdowns for vehicle details
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Center(
            //Wrap the dropdowns in a Form widget to manage form state and validation
            child: Form(
              key: _vehicleDetailsFormKey,
              autovalidateMode: AutovalidateMode.disabled,
              // Constrain the width of the form for better readability on larger screens
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 500),
                child: Column(
                  // Stretch the dropdowns to fill the width of the form
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    // YEAR DROPDOWN WITH AUTOCOMPLETE
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        // If the input is empty, show all year options
                        if (textEditingValue.text.isEmpty) {
                          return _yearOptions;
                        }
                        // Filter the year options based on the user's input, ignoring case
                        return _yearOptions.where(
                          (year) => year.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return CustomDropDown(
                          context: context,
                          onSelected: onSelected,
                          options: options,
                        );
                      },
                      // When the user selects an option from the autocomplete suggestions, update the selected year in the state
                      onSelected: (String selection) {
                        setState(() {
                          _selectedYear = selection;
                        });
                      },
                      // Custom field view builder to use a TextFormField for the autocomplete input,
                      //allowing us to integrate it with form validation
                      fieldViewBuilder:
                          (
                            context,
                            textController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            // Set the initial value of the text controller to the currently selected year, if any
                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration(
                                labelText: 'Vehicle Year',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedYear = value;
                                });
                              },
                              // Validate that the year field is not empty and contains a valid number when the form is submitted
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Year is required.';
                                }
                                final year = int.tryParse(v.trim());
                                if (year == null ||
                                    year < 1886 ||
                                    year > DateTime.now().year + 1) {
                                  return 'Please enter a valid year.';
                                }
                                return null;
                              },
                            );
                          },
                    ),

                    // MAKE DROPDOWN WITH AUTOCOMPLETE
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        // If the input is empty, show all make options
                        if (textEditingValue.text.isEmpty) {
                          return _makeOptions;
                        }
                        // Filter the make options based on the user's input, ignoring case
                        return _makeOptions.where(
                          (make) => make.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return CustomDropDown(
                          context: context,
                          onSelected: onSelected,
                          options: options,
                        );
                      },
                      // When the user selects an option from the autocomplete suggestions, update the selected make in the state
                      onSelected: (String selection) {
                        _handleMakeSelection(selection);
                      },
                      // Custom field view builder to use a TextFormField for the autocomplete input,
                      //allowing us to integrate it with form validation
                      fieldViewBuilder:
                          (
                            context,
                            textController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            // Set the initial value of the text controller to the currently selected make, if any
                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: _inputDecoration(
                                labelText: 'Vehicle Make',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedMake = value;
                                  _selectedModel = null;
                                  _modelOptions.clear();
                                });
                              },
                              // Validate that the make field is not empty when the form is submitted
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Make is required.'
                                  : null,
                            );
                          },
                    ),

                    // MODEL DROPDOWN WITH AUTOCOMPLETE
                    Autocomplete<String>(
                      key: ValueKey(_selectedMake ?? 1),
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _modelOptions;
                        }
                        // Filter the model options based on the user's input, ignoring case
                        return _modelOptions.where(
                          (model) => model.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return CustomDropDown(
                          context: context,
                          onSelected: onSelected,
                          options: options,
                        );
                      },
                      // When the user selects an option from the autocomplete suggestions,
                      //update the selected model in the state
                      onSelected: (String selection) {
                        setState(() {
                          _selectedModel = selection;
                        });
                      },
                      // Custom field view builder to use a TextFormField for the autocomplete input,
                      //allowing us to integrate it with form validation
                      fieldViewBuilder:
                          (
                            context,
                            textController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            // Set the initial value of the text controller to the currently selected model, if any
                            return TextFormField(
                              controller: textController,
                              focusNode: focusNode,
                              decoration: _inputDecoration(
                                labelText: 'Vehicle Model',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _selectedModel = value;
                                });
                              },
                              // Validate that the model field is not empty when the form is submitted
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Model is required'
                                  : null,
                            );
                          },
                    ),

                    // COLOR DROPDOWN
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue textEditingValue) {
                        if (textEditingValue.text.isEmpty) {
                          return _colorOptions;
                        }
                        return _colorOptions.where(
                          (color) => color.toLowerCase().contains(
                            textEditingValue.text.toLowerCase(),
                          ),
                        );
                      },
                      optionsViewBuilder: (context, onSelected, options) {
                        return ColorDropDown(
                          context: context,
                          onSelected: onSelected,
                          options: options,
                        );
                      },
                      onSelected: (String selection) {
                        setState(() {
                          _selectedColor = selection;
                        });
                      },
                      fieldViewBuilder:
                          (
                            context,
                            textController,
                            focusNode,
                            onFieldSubmitted,
                          ) {
                            return ValueListenableBuilder<TextEditingValue>(
                              valueListenable: textController,
                              builder: (context, value, child) {
                                final colorName = value.text.trim();
                                final swatch = _colorHelper.resolveColor(
                                  colorName,
                                );

                                return TextFormField(
                                  controller: textController,
                                  focusNode: focusNode,
                                  decoration:
                                      _inputDecoration(
                                        labelText: 'Vehicle Color',
                                      ).copyWith(
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: swatch != Colors.transparent
                                              ? Container(
                                                  width: 20,
                                                  height: 20,
                                                  decoration: BoxDecoration(
                                                    color: swatch,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                    border: Border.all(
                                                      color: Colors.black12,
                                                    ),
                                                  ),
                                                )
                                              : Icon(
                                                  Icons.color_lens,
                                                  color: UNHColorsPalette
                                                      .graniteGray,
                                                ),
                                        ),
                                      ),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedColor = value;
                                    });
                                  },
                                  validator: (v) =>
                                      (v == null || v.trim().isEmpty)
                                      ? 'Color is required'
                                      : null,
                                );
                              },
                            );
                          },
                    ),

                    // Section for vehicle photo upload
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 8,
                      children: [
                        Text(
                          'Vehicle Photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: UNHColorsPalette.unhWildcatBlue,
                          ),
                        ),
                        // Button to trigger the image picker for uploading a vehicle photo
                        OutlinedButton.icon(
                          onPressed: _isSubmitting ? null : _pickVehiclePhoto,
                          icon: const Icon(Icons.add_a_photo),
                          label: const Text('Upload Vehicle Photo'),
                        ),

                        // If a photo has been selected, display the name of the selected file
                        if (_vehiclePhoto != null)
                          Text(
                            'Selected: ${_vehiclePhoto!.name}',
                            style: TextStyle(
                              color: UNHColorsPalette.graniteGray,
                            ),
                          ),
                      ],
                    ),

                    // Section for license plate input, allowing the user to choose between typing in their license plate or uploading a photo of it
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 12,
                      children: [
                        Text(
                          'License Plate Input',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: UNHColorsPalette.unhWildcatBlue,
                          ),
                        ),
                        // Segmented button to toggle between the two input methods for the license plate
                        SegmentedButton<LicensePlateInputMethod>(
                          showSelectedIcon: false,
                          style: SegmentedButton.styleFrom(
                            foregroundColor: UNHColorsPalette.unhWildcatBlue,
                            backgroundColor: UNHColorsPalette.freshSnow,
                            selectedBackgroundColor:
                                UNHColorsPalette.unhWildcatBlue,
                            selectedForegroundColor: UNHColorsPalette.freshSnow,
                          ),
                          segments: const [
                            // Define the two segments for the input method selection: "Typed In" and "Upload Photo"
                            ButtonSegment(
                              value: LicensePlateInputMethod.typed,
                              label: Text('Typed In'),
                            ),
                            ButtonSegment(
                              value: LicensePlateInputMethod.photo,
                              label: Text('Upload Photo'),
                            ),
                          ],
                          // Set the currently selected input method based on the state variable
                          selected: {_licensePlateInputMethod},
                          onSelectionChanged: (selectedMethod) {
                            setState(() {
                              _licensePlateInputMethod = selectedMethod.first;
                            });
                          },
                        ),

                        // Conditionally show either a text field for typing in or a button to upload a photo
                        if (_licensePlateInputMethod ==
                            LicensePlateInputMethod.typed)
                          TextFormField(
                            controller: _licensePlateController,
                            maxLength: 8,
                            textCapitalization: TextCapitalization.characters,
                            decoration: _inputDecoration(
                              labelText: 'License Plate',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'License plate is required'
                                : null,
                          )
                        // If the user has selected the photo upload method
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 8,
                            children: [
                              // Button to trigger the image picker for uploading a license plate photo
                              OutlinedButton.icon(
                                onPressed: _isSubmitting
                                    ? null
                                    : _pickLicensePlatePhoto,
                                icon: const Icon(Icons.upload_file),
                                label: const Text('Upload License Plate Photo'),
                              ),
                              // If a photo has been selected, display the name of the selected file
                              if (_licensePlatePhoto != null)
                                Text(
                                  'Selected: ${_licensePlatePhoto!.name}',
                                  style: TextStyle(
                                    color: UNHColorsPalette.graniteGray,
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),

                    SizedBox(height: 8),
                    // Button to submit the vehicle details, currently just shows a SnackBar confirmation when pressed
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: UNHColorsPalette.unhWildcatBlue,
                        foregroundColor: UNHColorsPalette.freshSnow,
                        // Add vertical padding to make the button taller and easier to tap
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (_isSubmitting) return;

                              if (!_vehicleDetailsFormKey.currentState!
                                  .validate()) {
                                return;
                              }

                              final make = _selectedMake ?? '';
                              final model = _selectedModel ?? '';
                              final year = _selectedYear?.toString() ?? '';
                              final color = _selectedColor ?? '';
                              final licensePlate = _licensePlateController.text
                                  .trim();

                              if (licensePlate.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Please enter the license plate using Typed In before submitting.',
                                    ),
                                  ),
                                );
                                return;
                              }

                              setState(() {
                                _isSubmitting = true;
                              });

                              try {
                                final vehicleRef = _vehicleService
                                    .createVehicleDocRef();
                                final vehicleId = vehicleRef.id;
                                final uid = _vehicleService.currentUid;

                                String? vehiclePhotoUrl;
                                String? licensePlatePhotoUrl;

                                if (_vehiclePhoto != null) {
                                  vehiclePhotoUrl = await _storageService
                                      .uploadVehiclePhoto(
                                        uid: uid,
                                        vehicleId: vehicleId,
                                        file: _vehiclePhoto!,
                                      );
                                }

                                if (_licensePlatePhoto != null) {
                                  licensePlatePhotoUrl = await _storageService
                                      .uploadLicensePlatePhoto(
                                        uid: uid,
                                        vehicleId: vehicleId,
                                        file: _licensePlatePhoto!,
                                      );
                                }

                                await _vehicleService.createVehicle(
                                  vehicleId: vehicleId,
                                  make: make,
                                  model: model,
                                  year: year,
                                  color: color,
                                  licensePlate: licensePlate,
                                  vehiclePhotoUrl: vehiclePhotoUrl,
                                  licensePlatePhotoUrl: licensePlatePhotoUrl,
                                );

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Vehicle saved successfully.',
                                    ),
                                  ),
                                );
                                Navigator.pop(context, true);
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Failed to save vehicle: $e'),
                                  ),
                                );
                              } finally {
                                if (mounted) {
                                  setState(() {
                                    _isSubmitting = false;
                                  });
                                }
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit Vehicle'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CustomDropDown extends StatelessWidget {
  final BuildContext context;
  final Function(String) onSelected;
  final Iterable<String> options;

  const CustomDropDown({
    super.key,
    required this.context,
    required this.onSelected,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Material(
          elevation: 4,
          color: UNHColorsPalette.freshSnow,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return ListTile(
                  title: Text(option),
                  tileColor: Colors.transparent,
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class ColorDropDown extends StatelessWidget {
  final BuildContext context;
  final Function(String) onSelected;
  final Iterable<String> options;

  const ColorDropDown({
    super.key,
    required this.context,
    required this.onSelected,
    required this.options,
  });

  // Helper method to build a custom menu item for the color dropdown,
  //showing a small swatch of the color next to its name
  Widget _buildColorMenuItem(String colorName) {
    final swatchColor = ColorHelper().resolveColor(colorName);

    return Row(
      children: [
        // Small square showing the color swatch, with a border for visibility against light colors
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color:
                swatchColor, // Set the background color of the swatch based on the color name
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black12),
          ),
        ),
        SizedBox(width: 10),
        Text(colorName),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Material(
          elevation: 4,
          color: UNHColorsPalette.freshSnow,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              itemBuilder: (context, index) {
                final option = options.elementAt(index);
                return ListTile(
                  title: _buildColorMenuItem(option),
                  tileColor: Colors.transparent,
                  onTap: () => onSelected(option),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
