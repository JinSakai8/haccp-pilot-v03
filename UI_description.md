# UI Description (Sprint 6 Refresh)

Data aktualizacji: 2026-02-20  
Status: Zgodne z aktualnym routingiem i katalogiem widgetow

---

## 1. Zasady UI

Zasady globalne wynikajace z kodu:

- Dark theme: `lib/core/theme/app_theme.dart`
- Design tokens: `lib/core/constants/design_tokens.dart`
- Font: Work Sans
- Minimalny touch target: `60dp` (`HaccpDesignTokens.minTouchTarget`)

---

## 2. Mapa ekranow (wg routera)

Zrodlo: `lib/core/router/app_router.dart`, `lib/core/router/route_names.dart`

### Auth i Dashboard

- `/` -> `SplashScreen`
- `/login` -> `PinPadScreen`
- `/zone-select` -> `ZoneSelectionScreen`
- `/hub` -> `DashboardHubScreen`

### M02 Monitoring

- `/monitoring` -> `TemperatureDashboardScreen`
- `/monitoring/alarms` -> `AlarmsPanelScreen`
- `/monitoring/chart/:deviceId` -> `SensorChartScreen`

### M03 GMP

- `/gmp` -> `GmpProcessSelectorScreen`
- `/gmp/roasting` -> `MeatRoastingFormScreen`
- `/gmp/cooling` -> `FoodCoolingFormScreen`
- `/gmp/delivery` -> `DeliveryControlFormScreen`
- `/gmp/history` -> `GmpHistoryScreen`

### M04 GHP

- `/ghp` -> `GhpCategorySelectorScreen`
- `/ghp/checklist` -> `GhpChecklistScreen` (kategoria przez `state.extra`)
- `/ghp/chemicals` -> `GhpChemicalsScreen`
- `/ghp/history` -> `GhpHistoryScreen`

### M05 Waste

- `/waste` -> `WastePanelScreen`
- `/waste/register` -> `WasteRegistrationFormScreen`
- `/waste/camera` -> `HaccpCameraScreen`
- `/waste/history` -> `WasteHistoryScreen`

### M06 Reports

- `/reports` -> `ReportsPanelScreen`
- `/reports/preview/local` -> `PdfPreviewScreen`
- `/reports/preview/ccp3?date=YYYY-MM-DD` -> `Ccp3PreviewScreen`
- `/reports/history` -> `SavedReportsScreen`
- `/reports/drive` -> `DriveStatusScreen`

### M07 HR (restricted)

- `/hr` -> `HrDashboardScreen`
- `/hr/list` -> `EmployeeListScreen`
- `/hr/add` -> `AddEmployeeScreen`
- `/hr/employee/:id` -> `EmployeeProfileScreen`

### M08 Settings (restricted)

- `/settings` -> `GlobalSettingsScreen`
- `/settings/products` -> `ManageProductsScreen`

---

## 3. Guardy nawigacyjne

W routerze sa aktywne:

1. Guard logowania (`currentUserProvider`).
2. Guard roli dla tras HR i Settings (`employee.isManager`).

---

## 4. Katalog widgetow wspolnych

Canonical widgety w `lib/core/widgets`:

- `haccp_top_bar.dart`
- `haccp_tile.dart`
- `haccp_long_press_button.dart`
- `haccp_num_pad.dart`
- `haccp_stepper.dart`
- `haccp_toggle.dart`
- `haccp_time_picker.dart`
- `haccp_date_picker.dart`
- `haccp_text_input.dart`
- `haccp_numpad_input.dart`
- `success_overlay.dart`
- `empty_state_widget.dart`
- `offline_banner.dart`

Uwagi:

- Po Sprint 2 duplikaty dynamic-form widgetow zostaly usuniete.
- Jedynym widgetem specyficznym dla dynamic form pozostaje `haccp_dropdown.dart` w `lib/features/shared/widgets/dynamic_form`.

---

## 5. Dynamic forms

Silnik formularzy:

- `lib/features/shared/widgets/dynamic_form/dynamic_form_renderer.dart`

Definicje formularzy:

- `lib/features/shared/config/form_definitions.dart`
- `lib/features/shared/models/form_definition.dart`
- `lib/features/shared/providers/dynamic_form_provider.dart`

Checklisty GHP:

- `lib/features/shared/config/checklist_definitions.dart`

---

## 6. Ekrany i pliki per modul

### M01 Auth

- `lib/features/m01_auth/screens/splash_screen.dart`
- `lib/features/m01_auth/screens/pin_pad_screen.dart`
- `lib/features/m01_auth/screens/zone_selection_screen.dart`

### Dashboard

- `lib/features/dashboard/screens/dashboard_hub_screen.dart`

### M02 Monitoring

- `lib/features/m02_monitoring/screens/temperature_dashboard_screen.dart`
- `lib/features/m02_monitoring/screens/sensor_chart_screen.dart`
- `lib/features/m02_monitoring/screens/alarms_panel_screen.dart`

### M03 GMP

- `lib/features/m03_gmp/screens/gmp_process_selector_screen.dart`
- `lib/features/m03_gmp/screens/meat_roasting_form_screen.dart`
- `lib/features/m03_gmp/screens/food_cooling_form_screen.dart`
- `lib/features/m03_gmp/screens/delivery_control_form_screen.dart`
- `lib/features/m03_gmp/screens/gmp_history_screen.dart`

### M04 GHP

- `lib/features/m04_ghp/screens/ghp_category_selector_screen.dart`
- `lib/features/m04_ghp/screens/ghp_checklist_screen.dart`
- `lib/features/m04_ghp/screens/ghp_chemicals_screen.dart`
- `lib/features/m04_ghp/screens/ghp_history_screen.dart`

### M05 Waste

- `lib/features/m05_waste/screens/waste_panel_screen.dart`
- `lib/features/m05_waste/screens/waste_registration_form_screen.dart`
- `lib/features/m05_waste/screens/haccp_camera_screen.dart`
- `lib/features/m05_waste/screens/waste_history_screen.dart`

### M06 Reports

- `lib/features/m06_reports/screens/reports_panel_screen.dart`
- `lib/features/m06_reports/screens/pdf_preview_screen.dart`
- `lib/features/m06_reports/screens/ccp3_preview_screen.dart`
- `lib/features/m06_reports/screens/saved_reports_screen.dart`
- `lib/features/m06_reports/screens/drive_status_screen.dart`

### M07 HR

- `lib/features/m07_hr/screens/hr_dashboard_screen.dart`
- `lib/features/m07_hr/screens/employee_list_screen.dart`
- `lib/features/m07_hr/screens/add_employee_screen.dart`
- `lib/features/m07_hr/screens/employee_profile_screen.dart`

### M08 Settings

- `lib/features/m08_settings/screens/global_settings_screen.dart`
- `lib/features/m08_settings/screens/manage_products_screen.dart`
