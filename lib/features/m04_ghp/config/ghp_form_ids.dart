const String ghpFormPrefix = 'ghp_';

const String ghpPersonnelFormId = 'ghp_personnel';
const String ghpRoomsFormId = 'ghp_rooms';
const String ghpMaintenanceFormId = 'ghp_maintenance';
const String ghpChemicalsFormId = 'ghp_chemicals';

String ghpFormIdFromCategory(String categoryId) {
  switch (categoryId) {
    case 'personnel':
      return ghpPersonnelFormId;
    case 'rooms':
      return ghpRoomsFormId;
    case 'maintenance':
      return ghpMaintenanceFormId;
    case 'chemicals':
      return ghpChemicalsFormId;
    default:
      return '$ghpFormPrefix$categoryId';
  }
}
